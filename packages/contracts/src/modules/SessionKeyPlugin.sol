// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC7579Module} from "../interfaces/IERC7579Module.sol";

/// @title SessionKeyPlugin
/// @notice ERC-7579 validator module implementing AP2 Intent Mandates
/// @dev Enforces human-signed authorization for all agent-led transactions
/// @custom:security-contact security@agentpay.xyz
contract SessionKeyPlugin is IERC7579Module {
    // ============ ERRORS ============
    error Unauthorized();
    error IntentExpired();
    error PriceCeilingExceeded();
    error RecipientNotWhitelisted();
    error InvalidSignature();
    error IntentAlreadyUsed();
    error IntentNotFound();
    error InvalidIntentData();
    error SessionKeyNotAuthorized();

    // ============ EVENTS ============
    event IntentAuthorized(
        bytes32 indexed intentHash,
        address indexed account,
        address indexed sessionKey,
        uint256 priceCeiling,
        uint48 expiry
    );
    event IntentExecuted(
        bytes32 indexed intentHash,
        address indexed account,
        address recipient,
        uint256 amount
    );
    event IntentRevoked(bytes32 indexed intentHash, address indexed account);
    event SessionKeyAdded(address indexed account, address indexed sessionKey);
    event SessionKeyRevoked(address indexed account, address indexed sessionKey);

    // ============ CONSTANTS ============
    uint256 constant MODULE_TYPE_VALIDATOR = 1;
    
    /// @notice EIP-712 domain separator type hash
    bytes32 public constant DOMAIN_TYPEHASH = 
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    
    /// @notice AP2 Intent Mandate type hash
    bytes32 public constant INTENT_TYPEHASH = 
        keccak256(
            "IntentMandate(address account,address sessionKey,address[] whitelist,uint256 priceCeiling,uint48 expiry,uint256 nonce)"
        );

    // ============ STRUCTS ============

    /// @notice AP2 Intent Mandate - Human-signed authorization for agent actions
    /// @dev All agent transactions must have a matching Intent Mandate
    struct IntentMandate {
        address account;           // Account executing the intent
        address sessionKey;        // Authorized session key (agent's key)
        address[] whitelist;       // Approved recipient addresses
        uint256 priceCeiling;      // Maximum amount per transaction
        uint48 expiry;             // Intent expiration timestamp
        uint256 nonce;             // Replay protection nonce
        bytes signature;           // Human's signature (owner)
    }

    /// @notice Stored intent state after validation
    struct IntentState {
        address sessionKey;
        uint256 priceCeiling;
        uint48 expiry;
        bool executed;
        mapping(address => bool) whitelist;
    }

    // ============ STORAGE ============

    /// @notice Account => SessionKey => Authorized
    mapping(address => mapping(address => bool)) public authorizedSessionKeys;

    /// @notice Account => IntentHash => IntentState
    mapping(address => mapping(bytes32 => IntentState)) private _intents;

    /// @notice Account => Nonce (for replay protection)
    mapping(address => uint256) public nonces;

    /// @notice Account => Initialized
    mapping(address => bool) private _initialized;

    /// @notice EIP-712 domain separator
    bytes32 public immutable DOMAIN_SEPARATOR;

    // ============ CONSTRUCTOR ============

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("AgentPay SessionKeyPlugin")),
                keccak256(bytes("2")),
                block.chainid,
                address(this)
            )
        );
    }

    // ============ ERC-7579 MODULE INTERFACE ============

    /// @notice Initialize the module for an account
    /// @param data Encoded session keys to authorize
    function onInstall(bytes calldata data) external override {
        if (_initialized[msg.sender]) revert Unauthorized();
        
        _initialized[msg.sender] = true;

        // Decode and authorize initial session keys
        if (data.length > 0) {
            address[] memory sessionKeys = abi.decode(data, (address[]));
            for (uint256 i = 0; i < sessionKeys.length; i++) {
                _addSessionKey(msg.sender, sessionKeys[i]);
            }
        }
    }

    /// @notice De-initialize the module for an account
    function onUninstall(bytes calldata /* data */) external override {
        if (!_initialized[msg.sender]) revert Unauthorized();
        _initialized[msg.sender] = false;
    }

    /// @notice Check if the module is initialized for an account
    function isInitialized(address account) external view override returns (bool) {
        return _initialized[account];
    }

    /// @notice Get module type (validator)
    function moduleType() external pure override returns (uint256) {
        return MODULE_TYPE_VALIDATOR;
    }

    // ============ SESSION KEY MANAGEMENT ============

    /// @notice Add a session key for the account
    /// @param sessionKey Address of the session key to authorize
    function addSessionKey(address sessionKey) external {
        if (!_initialized[msg.sender]) revert Unauthorized();
        _addSessionKey(msg.sender, sessionKey);
    }

    /// @notice Revoke a session key
    /// @param sessionKey Address of the session key to revoke
    function revokeSessionKey(address sessionKey) external {
        if (!_initialized[msg.sender]) revert Unauthorized();
        authorizedSessionKeys[msg.sender][sessionKey] = false;
        emit SessionKeyRevoked(msg.sender, sessionKey);
    }

    /// @notice Internal function to add session key
    function _addSessionKey(address account, address sessionKey) internal {
        authorizedSessionKeys[account][sessionKey] = true;
        emit SessionKeyAdded(account, sessionKey);
    }

    // ============ AP2 INTENT MANDATE AUTHORIZATION ============

    /// @notice Authorize an Intent Mandate with human signature
    /// @param intent The Intent Mandate to authorize
    /// @return intentHash The hash of the authorized intent
    function authorizeIntent(IntentMandate calldata intent) 
        external 
        returns (bytes32 intentHash) 
    {
        // Validate intent belongs to caller
        if (intent.account != msg.sender) revert Unauthorized();
        if (!_initialized[msg.sender]) revert Unauthorized();

        // Validate session key is authorized
        if (!authorizedSessionKeys[msg.sender][intent.sessionKey]) {
            revert SessionKeyNotAuthorized();
        }

        // Validate expiry
        if (intent.expiry <= block.timestamp) revert IntentExpired();

        // Validate nonce
        if (intent.nonce != nonces[msg.sender]) revert InvalidIntentData();

        // Compute intent hash
        intentHash = _hashIntent(intent);

        // Verify signature (must be signed by account owner)
        if (!_verifySignature(intentHash, intent.signature, msg.sender)) {
            revert InvalidSignature();
        }

        // Store intent state
        IntentState storage state = _intents[msg.sender][intentHash];
        state.sessionKey = intent.sessionKey;
        state.priceCeiling = intent.priceCeiling;
        state.expiry = intent.expiry;
        state.executed = false;

        // Store whitelist
        for (uint256 i = 0; i < intent.whitelist.length; i++) {
            state.whitelist[intent.whitelist[i]] = true;
        }

        // Increment nonce
        nonces[msg.sender]++;

        emit IntentAuthorized(
            intentHash,
            msg.sender,
            intent.sessionKey,
            intent.priceCeiling,
            intent.expiry
        );
    }

    /// @notice Validate a transaction against an Intent Mandate
    /// @param account The account executing the transaction
    /// @param intentHash The hash of the Intent Mandate
    /// @param sessionKey The session key attempting the transaction
    /// @param recipient The recipient of the transaction
    /// @param amount The amount being transferred
    /// @return valid Whether the transaction is valid
    function validateIntent(
        address account,
        bytes32 intentHash,
        address sessionKey,
        address recipient,
        uint256 amount
    ) external returns (bool valid) {
        IntentState storage state = _intents[account][intentHash];

        // Check intent exists
        if (state.sessionKey == address(0)) revert IntentNotFound();

        // Check not already executed
        if (state.executed) revert IntentAlreadyUsed();

        // Check session key matches
        if (state.sessionKey != sessionKey) revert SessionKeyNotAuthorized();

        // Check not expired
        if (block.timestamp > state.expiry) revert IntentExpired();

        // Check price ceiling
        if (amount > state.priceCeiling) revert PriceCeilingExceeded();

        // Check recipient is whitelisted
        if (!state.whitelist[recipient]) revert RecipientNotWhitelisted();

        // Mark as executed
        state.executed = true;

        emit IntentExecuted(intentHash, account, recipient, amount);

        return true;
    }

    /// @notice Revoke an Intent Mandate
    /// @param intentHash The hash of the intent to revoke
    function revokeIntent(bytes32 intentHash) external {
        if (!_initialized[msg.sender]) revert Unauthorized();
        
        IntentState storage state = _intents[msg.sender][intentHash];
        if (state.sessionKey == address(0)) revert IntentNotFound();

        // Mark as executed to prevent use
        state.executed = true;

        emit IntentRevoked(intentHash, msg.sender);
    }

    // ============ VALIDATION FUNCTIONS ============

    /// @notice Validate user operation (ERC-4337 compatible)
    /// @param userOp The user operation to validate
    /// @param userOpHash The hash of the user operation
    /// @return validationData Validation result (0 = valid)
    function validateUserOp(
        bytes calldata userOp,
        bytes32 userOpHash
    ) external view returns (uint256 validationData) {
        // Decode userOp to extract account, sessionKey, intentHash
        (
            address account,
            bytes32 intentHash,
            address sessionKey,
            address recipient,
            uint256 amount
        ) = abi.decode(userOp, (address, bytes32, address, address, uint256));

        // Validate intent
        IntentState storage state = _intents[account][intentHash];

        // Check intent exists
        if (state.sessionKey == address(0)) return 1; // Invalid

        // Check not already executed
        if (state.executed) return 1; // Invalid

        // Check session key matches
        if (state.sessionKey != sessionKey) return 1; // Invalid

        // Check not expired
        if (block.timestamp > state.expiry) return 1; // Invalid

        // Check price ceiling
        if (amount > state.priceCeiling) return 1; // Invalid

        // Check recipient is whitelisted
        if (!state.whitelist[recipient]) return 1; // Invalid

        return 0; // Valid
    }

    // ============ VIEW FUNCTIONS ============

    /// @notice Get intent state
    /// @param account The account that owns the intent
    /// @param intentHash The hash of the intent
    /// @return sessionKey The authorized session key
    /// @return priceCeiling The maximum amount per transaction
    /// @return expiry The expiration timestamp
    /// @return executed Whether the intent has been executed
    function getIntent(address account, bytes32 intentHash)
        external
        view
        returns (
            address sessionKey,
            uint256 priceCeiling,
            uint48 expiry,
            bool executed
        )
    {
        IntentState storage state = _intents[account][intentHash];
        return (
            state.sessionKey,
            state.priceCeiling,
            state.expiry,
            state.executed
        );
    }

    /// @notice Check if a recipient is whitelisted for an intent
    /// @param account The account that owns the intent
    /// @param intentHash The hash of the intent
    /// @param recipient The recipient to check
    /// @return whitelisted Whether the recipient is whitelisted
    function isWhitelisted(
        address account,
        bytes32 intentHash,
        address recipient
    ) external view returns (bool whitelisted) {
        return _intents[account][intentHash].whitelist[recipient];
    }

    /// @notice Compute the hash of an Intent Mandate
    /// @param intent The Intent Mandate to hash
    /// @return intentHash The EIP-712 hash of the intent
    function hashIntent(IntentMandate calldata intent) 
        external 
        view 
        returns (bytes32 intentHash) 
    {
        return _hashIntent(intent);
    }

    // ============ INTERNAL FUNCTIONS ============

    /// @notice Internal function to hash an Intent Mandate
    function _hashIntent(IntentMandate calldata intent) 
        internal 
        view 
        returns (bytes32) 
    {
        bytes32 structHash = keccak256(
            abi.encode(
                INTENT_TYPEHASH,
                intent.account,
                intent.sessionKey,
                keccak256(abi.encodePacked(intent.whitelist)),
                intent.priceCeiling,
                intent.expiry,
                intent.nonce
            )
        );

        return keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
    }

    /// @notice Verify EIP-712 signature
    /// @param hash The hash to verify
    /// @param signature The signature to verify
    /// @param signer The expected signer
    /// @return valid Whether the signature is valid
    function _verifySignature(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool valid) {
        if (signature.length != 65) return false;

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // EIP-2 still allows signature malleability for ecrecover()
        // Remove this possibility and make the signature unique
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }

        if (v != 27 && v != 28) {
            return false;
        }

        address recovered = ecrecover(hash, v, r, s);
        return recovered != address(0) && recovered == signer;
    }
}
