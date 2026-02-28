// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title IERC7579Account
/// @notice Minimal ERC-7579 modular account interface
interface IERC7579Account {
    event ModuleInstalled(uint256 moduleTypeId, address module);
    event ModuleUninstalled(uint256 moduleTypeId, address module);

    /// @notice Execute a transaction from the account
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    /// @notice Execute a batch of transactions
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) external payable returns (bytes[] memory);

    /// @notice Install a module
    function installModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata initData
    ) external;

    /// @notice Uninstall a module
    function uninstallModule(
        uint256 moduleTypeId,
        address module,
        bytes calldata deInitData
    ) external;

    /// @notice Check if a module is installed
    function isModuleInstalled(
        uint256 moduleTypeId,
        address module,
        bytes calldata additionalContext
    ) external view returns (bool);
}
