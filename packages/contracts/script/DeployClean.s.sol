// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {AgentFactoryClean} from "../src/AgentFactoryClean.sol";
import {AgentAccountClean} from "../src/AgentAccountClean.sol";

/// @title DeployClean
/// @notice Clean deployment script without escrow/reputation dependencies
contract DeployClean is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying clean contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy AgentFactoryClean
        AgentFactoryClean factory = new AgentFactoryClean();
        console.log("AgentFactoryClean deployed at:", address(factory));

        // Optional: Deploy a sample AgentAccountClean for testing
        bytes32 salt = keccak256(abi.encodePacked(deployer, uint256(0)));
        address agentAccount = factory.createAccount(deployer, salt);
        console.log("Sample AgentAccountClean deployed at:", agentAccount);

        vm.stopBroadcast();

        // Log deployment info
        console.log("\n=== Clean Deployment Summary ===");
        console.log("Network: Monad Testnet (ChainID: 10143)");
        console.log("AgentFactoryClean:", address(factory));
        console.log("Sample AgentAccountClean:", agentAccount);
        console.log("Owner:", deployer);
    }
}