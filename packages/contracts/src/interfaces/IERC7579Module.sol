// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title IERC7579Module
/// @notice Base interface for ERC-7579 modules
interface IERC7579Module {
    /// @notice Initialize the module for an account
    function onInstall(bytes calldata data) external;

    /// @notice De-initialize the module for an account
    function onUninstall(bytes calldata data) external;

    /// @notice Check if the module is initialized for an account
    function isInitialized(address account) external view returns (bool);

    /// @notice Get module type
    function moduleType() external view returns (uint256);
}
