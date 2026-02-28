// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC7579Account} from "./interfaces/IERC7579Account.sol";

/// @title AgentAccountClean
/// @notice Clean version of AgentAccount without escrow/reputation dependencies
/// @dev ERC-7579 modular account optimized for Monad parallel execution
contract AgentAccountClean is IERC7579Account {
    // ============ ERRORS ============
    error Unauthorized();
    error InvalidModule();
    error ModuleAlreadyInstalled();
    error ModuleNotInstalled();
    error ExecutionFailed();
    error InsufficientBalance();
    error SessionExpired();
    error SessionLimitExceeded();

    // ============ EVENTS ============
    event SessionCreated(bytes32 indexed sessionId, address indexed apiProvider, uint256 limit);
    event PaymentExecuted(bytes32 indexed sessionId, address indexed to, uint256 amount);

    // ============ CONSTANTS ============
    uint256 constant MODULE_TYPE_VALIDATOR = 1;
    uint256 constant MODULE_TYPE_EXECUTOR = 2;
    uint256 constant MODULE_TYPE_HOOK = 3;

    // ============ STORAGE LAYOUT (Session-Sharded for Monad Parallel Execution) ============
    
    /// @notice Account owner (single storage slot)
    address public owner;

    /// @notice Session-specific data (sharded by sessionId to avoid conflicts)
    /// @dev Each session has isolated storage - parallel txs with different sessionIds have ZERO conflicts
    struct SessionData {
        address apiProvider;      // API provider address
        uint256 spendLimit;       // Max spend per session
        uint256 spent;            // Amount spent in this session
        uint48 expiresAt;         // Session expiration timestamp
        bool active;              // Session active flag
    }
    
    /// @dev sessionId => SessionData (sharded storage)
    mapping(bytes32 => SessionData) private _sessions;

    /// @notice Module installation tracking (separate from session data)
    /// @dev moduleTypeId => module address => installed
    mapping(uint256 => mapping(address => bool)) private _installedModules;

    /// @notice Nonce for replay protection (per-session to avoid conflicts)
    /// @dev sessionId => nonce
    mapping(bytes32 => uint256) private _sessionNonces;

    // ============ MODIFIERS ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyOwnerOrSelf() {
        if (msg.sender != owner && msg.sender != address(this)) revert Unauthorized();
        _;
    }

    modifier validSession(bytes32 sessionId) {
        SessionData storage session = _sessions[sessionId];
        if (!session.active) revert Unauthorized();
        if (block.timestamp > session.expiresAt) revert SessionExpired();
        _;
    }

    // ============ CONSTRUCTOR ============
    
    constructor(address _owner) {
        owner = _owner;
    }

    // ============ SESSION MANAGEMENT (Optimized for Parallel Execution) ============

    /// @notice Create a new session for API payments
    /// @dev Each session has isolated storage - enables parallel execution
    /// @param apiProvider Address of the API provider
    /// @param spendLimit Maximum amount that can be spent in this session
    /// @param duration Session duration in seconds
    /// @return sessionId Unique session identifier
    function createSession(
        address apiProvider,
        uint256 spendLimit,
        uint48 duration
    ) external onlyOwner returns (bytes32 sessionId) {
        // Generate unique sessionId using keccak256 (deterministic but unique per call)
        sessionId = keccak256(
            abi.encodePacked(
                address(this),
                apiProvider,
                spendLimit,
                block.timestamp,
                _sessionNonces[bytes32(0)]++ // Global nonce for session creation
            )
        );

        SessionData storage session = _sessions[sessionId];
        session.apiProvider = apiProvider;
        session.spendLimit = spendLimit;
        session.spent = 0;
        session.expiresAt = uint48(block.timestamp + duration);
        session.active = true;

        emit SessionCreated(sessionId, apiProvider, spendLimit);
    }

    /// @notice Execute payment within a session
    /// @dev Session-sharded storage ensures parallel txs don't conflict
    /// @param sessionId Session identifier
    /// @param to Payment recipient
    /// @param amount Payment amount
    function executeSessionPayment(
        bytes32 sessionId,
        address to,
        uint256 amount
    ) external validSession(sessionId) {
        SessionData storage session = _sessions[sessionId];
        
        // Check spend limit (single SLOAD from sharded storage)
        if (session.spent + amount > session.spendLimit) revert SessionLimitExceeded();
        
        // Check balance
        if (address(this).balance < amount) revert InsufficientBalance();

        // Update spent amount (single SSTORE to sharded storage)
        session.spent += amount;

        // Execute payment
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert ExecutionFailed();

        emit PaymentExecuted(sessionId, to, amount);
    }

    /// @notice Revoke a session
    function revokeSession(bytes32 sessionId) external onlyOwner {
        _sessions[sessionId].active = false;
    }

    /// @notice Get session data
    function getSession(bytes32 sessionId) external view returns (SessionData memory) {
        return _sessions[sessionId];
    }

    // ============ ERC-7579 EXECUTION ============

    /// @notice Execute a single transaction
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable onlyOwnerOrSelf returns (bytes memory result) {
        if (address(this).balance < value) revert InsufficientBalance();
        
        bool success;
        (success, result) = target.call{value: value}(data);
        if (!success) revert ExecutionFailed();
    }

    /// @notice Execute a batch of transactions
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) external payable onlyOwnerOrSelf returns (bytes[] memory results) {
        uint256 length = targets.length;
        results = new bytes[](length);

        for (uint256 i = 0; i < length; i++) {
            bool success;
            (success, results[i]) = targets[i].call{value: values[i]}(data[i]);
            if (!success) revert ExecutionFailed();
        }
    }

    // ============ ERC-7579 MODULE MANAGEMENT ============

    function installModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata initData
    ) external onlyOwner {
        if (module == address(0)) revert InvalidModule();
        if (_installedModules[moduleTypeId][module]) revert ModuleAlreadyInstalled();

        _installedModules[moduleTypeId][module] = true;

        // Call module's onInstall if it has code
        if (module.code.length > 0) {
            (bool success, ) = module.call(
                abi.encodeWithSignature("onInstall(bytes)", initData)
            );
            if (!success) revert ExecutionFailed();
        }

        emit ModuleInstalled(moduleTypeId, module);
    }

    function uninstallModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata deInitData
    ) external onlyOwner {
        if (!_installedModules[moduleTypeId][module]) revert ModuleNotInstalled();

        _installedModules[moduleTypeId][module] = false;

        // Call module's onUninstall if it has code
        if (module.code.length > 0) {
            (bool success, ) = module.call(
                abi.encodeWithSignature("onUninstall(bytes)", deInitData)
            );
            if (!success) revert ExecutionFailed();
        }

        emit ModuleUninstalled(moduleTypeId, module);
    }

    function isModuleInstalled(
        uint256 moduleTypeId,
        address module,
        bytes calldata /* additionalContext */
    ) external view returns (bool) {
        return _installedModules[moduleTypeId][module];
    }

    // ============ RECEIVE ETHER ============
    
    receive() external payable {}
}