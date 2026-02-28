// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {AgentAccountClean} from "../src/AgentAccountClean.sol";
import {AgentFactoryClean} from "../src/AgentFactoryClean.sol";

contract AgentAccountCleanTest is Test {
    AgentAccountClean public account;
    AgentFactoryClean public factory;
    
    address public owner = address(0x1);
    address public apiProvider = address(0x2);
    address public attacker = address(0x3);

    function setUp() public {
        factory = new AgentFactoryClean();
        
        // Deploy account via factory
        vm.prank(owner);
        bytes32 salt = keccak256(abi.encodePacked(owner, uint256(0)));
        address accountAddr = factory.createAccount(owner, salt);
        account = AgentAccountClean(payable(accountAddr));

        // Fund the account
        vm.deal(accountAddr, 10 ether);
    }

    // ============ SESSION TESTS ============

    function testCreateSession() public {
        vm.prank(owner);
        bytes32 sessionId = account.createSession(
            apiProvider,
            1 ether,
            1 days
        );

        AgentAccountClean.SessionData memory session = account.getSession(sessionId);
        assertEq(session.apiProvider, apiProvider);
        assertEq(session.spendLimit, 1 ether);
        assertEq(session.spent, 0);
        assertTrue(session.active);
    }

    function testExecuteSessionPayment() public {
        // Create session
        vm.prank(owner);
        bytes32 sessionId = account.createSession(
            apiProvider,
            1 ether,
            1 days
        );

        // Execute payment
        uint256 balanceBefore = apiProvider.balance;
        vm.prank(owner);
        account.executeSessionPayment(sessionId, apiProvider, 0.1 ether);

        assertEq(apiProvider.balance, balanceBefore + 0.1 ether);
        
        AgentAccountClean.SessionData memory session = account.getSession(sessionId);
        assertEq(session.spent, 0.1 ether);
    }

    function testSessionLimitExceeded() public {
        vm.prank(owner);
        bytes32 sessionId = account.createSession(
            apiProvider,
            0.5 ether,
            1 days
        );

        vm.prank(owner);
        vm.expectRevert(AgentAccountClean.SessionLimitExceeded.selector);
        account.executeSessionPayment(sessionId, apiProvider, 1 ether);
    }

    function testSessionExpired() public {
        vm.prank(owner);
        bytes32 sessionId = account.createSession(
            apiProvider,
            1 ether,
            1 hours
        );

        // Fast forward past expiration
        vm.warp(block.timestamp + 2 hours);

        vm.prank(owner);
        vm.expectRevert(AgentAccountClean.SessionExpired.selector);
        account.executeSessionPayment(sessionId, apiProvider, 0.1 ether);
    }

    function testRevokeSession() public {
        vm.prank(owner);
        bytes32 sessionId = account.createSession(
            apiProvider,
            1 ether,
            1 days
        );

        vm.prank(owner);
        account.revokeSession(sessionId);

        AgentAccountClean.SessionData memory session = account.getSession(sessionId);
        assertFalse(session.active);
    }

    function testUnauthorizedSessionCreation() public {
        vm.prank(attacker);
        vm.expectRevert(AgentAccountClean.Unauthorized.selector);
        account.createSession(apiProvider, 1 ether, 1 days);
    }

    // ============ PARALLEL EXECUTION TESTS ============

    function testParallelSessionPayments() public {
        // Create multiple sessions
        vm.startPrank(owner);
        bytes32 session1 = account.createSession(apiProvider, 1 ether, 1 days);
        bytes32 session2 = account.createSession(apiProvider, 1 ether, 1 days);
        bytes32 session3 = account.createSession(apiProvider, 1 ether, 1 days);
        vm.stopPrank();

        // Simulate parallel execution (different sessions = no storage conflicts)
        vm.prank(owner);
        account.executeSessionPayment(session1, apiProvider, 0.1 ether);
        
        vm.prank(owner);
        account.executeSessionPayment(session2, apiProvider, 0.2 ether);
        
        vm.prank(owner);
        account.executeSessionPayment(session3, apiProvider, 0.3 ether);

        // Verify each session tracked independently
        assertEq(account.getSession(session1).spent, 0.1 ether);
        assertEq(account.getSession(session2).spent, 0.2 ether);
        assertEq(account.getSession(session3).spent, 0.3 ether);
    }

    // ============ EXECUTION TESTS ============

    function testExecute() public {
        address target = address(0x4);
        
        vm.prank(owner);
        account.execute(target, 0.5 ether, "");

        assertEq(target.balance, 0.5 ether);
    }

    function testExecuteBatch() public {
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory data = new bytes[](3);

        targets[0] = address(0x4);
        targets[1] = address(0x5);
        targets[2] = address(0x6);
        
        values[0] = 0.1 ether;
        values[1] = 0.2 ether;
        values[2] = 0.3 ether;

        vm.prank(owner);
        account.executeBatch(targets, values, data);

        assertEq(targets[0].balance, 0.1 ether);
        assertEq(targets[1].balance, 0.2 ether);
        assertEq(targets[2].balance, 0.3 ether);
    }

    // ============ MODULE TESTS ============

    function testInstallModule() public {
        address module = address(0x7);
        
        vm.prank(owner);
        account.installModule(1, module, "");

        assertTrue(account.isModuleInstalled(1, module, ""));
    }

    function testUninstallModule() public {
        address module = address(0x7);
        
        vm.startPrank(owner);
        account.installModule(1, module, "");
        account.uninstallModule(1, module, "");
        vm.stopPrank();

        assertFalse(account.isModuleInstalled(1, module, ""));
    }

    function testCannotInstallModuleTwice() public {
        address module = address(0x7);
        
        vm.startPrank(owner);
        account.installModule(1, module, "");
        
        vm.expectRevert(AgentAccountClean.ModuleAlreadyInstalled.selector);
        account.installModule(1, module, "");
        vm.stopPrank();
    }

    // ============ GAS OPTIMIZATION TESTS ============

    function testGasOptimizedSessionPayment() public {
        vm.prank(owner);
        bytes32 sessionId = account.createSession(apiProvider, 1 ether, 1 days);

        uint256 gasBefore = gasleft();
        vm.prank(owner);
        account.executeSessionPayment(sessionId, apiProvider, 0.01 ether);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for session payment:", gasUsed);
        // Should be < 90k gas for micro-payment to be economical on Monad
        assertLt(gasUsed, 90000);
    }
}