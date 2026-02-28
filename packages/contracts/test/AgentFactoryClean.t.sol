// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {AgentFactoryClean} from "../src/AgentFactoryClean.sol";
import {AgentAccountClean} from "../src/AgentAccountClean.sol";

contract AgentFactoryCleanTest is Test {
    AgentFactoryClean public factory;
    address public owner = address(0x1);

    function setUp() public {
        factory = new AgentFactoryClean();
    }

    function testCreateAccount() public {
        bytes32 salt = keccak256(abi.encodePacked(owner, uint256(0)));
        
        vm.prank(owner);
        address account = factory.createAccount(owner, salt);

        assertTrue(factory.isAccount(account));
        assertEq(factory.accountCount(), 1);
        assertEq(AgentAccountClean(payable(account)).owner(), owner);
    }

    function testDeterministicAddress() public {
        bytes32 salt = keccak256(abi.encodePacked(owner, uint256(0)));
        
        // Predict address
        address predicted = factory.getAddress(owner, salt);

        // Deploy account
        vm.prank(owner);
        address actual = factory.createAccount(owner, salt);

        // Addresses should match
        assertEq(predicted, actual);
    }

    function testCannotDeployTwice() public {
        bytes32 salt = keccak256(abi.encodePacked(owner, uint256(0)));
        
        vm.startPrank(owner);
        factory.createAccount(owner, salt);
        
        vm.expectRevert(AgentFactoryClean.AccountAlreadyExists.selector);
        factory.createAccount(owner, salt);
        vm.stopPrank();
    }

    function testGetOrCreateAccount() public {
        bytes32 salt = keccak256(abi.encodePacked(owner, uint256(0)));
        
        // First call creates account
        vm.prank(owner);
        address account1 = factory.getOrCreateAccount(owner, salt);
        assertTrue(factory.isAccount(account1));

        // Second call returns existing account
        vm.prank(owner);
        address account2 = factory.getOrCreateAccount(owner, salt);
        assertEq(account1, account2);
        assertEq(factory.accountCount(), 1); // Only one account created
    }

    function testGenerateSalt() public {
        bytes32 salt1 = factory.generateSalt(owner, 0);
        bytes32 salt2 = factory.generateSalt(owner, 1);
        bytes32 salt3 = factory.generateSalt(owner, 0);

        // Different indices produce different salts
        assertTrue(salt1 != salt2);
        
        // Same inputs produce same salt
        assertEq(salt1, salt3);
    }

    function testMultipleAccountsPerOwner() public {
        vm.startPrank(owner);
        
        bytes32 salt1 = factory.generateSalt(owner, 0);
        bytes32 salt2 = factory.generateSalt(owner, 1);
        bytes32 salt3 = factory.generateSalt(owner, 2);

        address account1 = factory.createAccount(owner, salt1);
        address account2 = factory.createAccount(owner, salt2);
        address account3 = factory.createAccount(owner, salt3);

        vm.stopPrank();

        // All accounts should be different
        assertTrue(account1 != account2);
        assertTrue(account2 != account3);
        assertTrue(account1 != account3);

        // All should be tracked
        assertTrue(factory.isAccount(account1));
        assertTrue(factory.isAccount(account2));
        assertTrue(factory.isAccount(account3));
        assertEq(factory.accountCount(), 3);
    }

    function testGasOptimizedDeployment() public {
        bytes32 salt = keccak256(abi.encodePacked(owner, uint256(0)));
        
        uint256 gasBefore = gasleft();
        vm.prank(owner);
        factory.createAccount(owner, salt);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for account deployment:", gasUsed);
        // CREATE2 deployment should be gas-efficient
        assertLt(gasUsed, 1300000);
    }
}