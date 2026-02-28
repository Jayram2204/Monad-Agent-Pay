// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {AgentAccountClean} from "./AgentAccountClean.sol";

/// @title AgentFactoryClean
/// @notice Clean version of AgentFactory without escrow/reputation dependencies
/// @dev Factory for deploying AgentAccountClean contracts with CREATE2
contract AgentFactoryClean {
    // ============ EVENTS ============
    event AgentAccountCreated(
        address indexed account,
        address indexed owner,
        bytes32 indexed salt
    );

    // ============ ERRORS ============
    error DeploymentFailed();
    error AccountAlreadyExists();

    // ============ STATE ============
    
    /// @notice Mapping to track deployed accounts
    mapping(address => bool) public isAccount;

    /// @notice Total number of accounts created
    uint256 public accountCount;

    // ============ DEPLOYMENT ============

    /// @notice Deploy a new AgentAccountClean using CREATE2
    /// @param owner Address of the account owner
    /// @param salt Salt for CREATE2 deployment (enables deterministic addresses)
    /// @return account Address of the deployed AgentAccountClean
    function createAccount(
        address owner,
        bytes32 salt
    ) external returns (address account) {
        // Compute the deterministic address
        account = getAddress(owner, salt);

        // Check if account already exists
        if (isAccount[account]) revert AccountAlreadyExists();

        // Deploy using CREATE2
        bytes memory bytecode = abi.encodePacked(
            type(AgentAccountClean).creationCode,
            abi.encode(owner)
        );

        assembly {
            account := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        if (account == address(0)) revert DeploymentFailed();

        // Track the account
        isAccount[account] = true;
        accountCount++;

        emit AgentAccountCreated(account, owner, salt);
    }

    /// @notice Compute the deterministic address for an account
    /// @param owner Address of the account owner
    /// @param salt Salt for CREATE2 deployment
    /// @return account Predicted address of the AgentAccountClean
    function getAddress(
        address owner,
        bytes32 salt
    ) public view returns (address account) {
        bytes memory bytecode = abi.encodePacked(
            type(AgentAccountClean).creationCode,
            abi.encode(owner)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        account = address(uint160(uint256(hash)));
    }

    /// @notice Deploy an account if it doesn't exist, otherwise return existing address
    /// @param owner Address of the account owner
    /// @param salt Salt for CREATE2 deployment
    /// @return account Address of the AgentAccountClean
    function getOrCreateAccount(
        address owner,
        bytes32 salt
    ) external returns (address account) {
        account = getAddress(owner, salt);

        if (!isAccount[account]) {
            // Deploy using CREATE2
            bytes memory bytecode = abi.encodePacked(
                type(AgentAccountClean).creationCode,
                abi.encode(owner)
            );

            assembly {
                account := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            }

            if (account == address(0)) revert DeploymentFailed();

            // Track the account
            isAccount[account] = true;
            accountCount++;

            emit AgentAccountCreated(account, owner, salt);
        }
    }

    /// @notice Generate a deterministic salt based on owner and index
    /// @param owner Address of the account owner
    /// @param index Index for the account (allows multiple accounts per owner)
    /// @return salt Generated salt
    function generateSalt(address owner, uint256 index) external pure returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(owner, index));
    }
}