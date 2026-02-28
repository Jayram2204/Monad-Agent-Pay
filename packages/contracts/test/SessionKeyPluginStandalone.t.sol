// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {SessionKeyPlugin} from "../src/modules/SessionKeyPlugin.sol";
import {AgentAccountClean} from "../src/AgentAccountClean.sol";

contract SessionKeyPluginStandaloneTest is Test {
    SessionKeyPlugin public plugin;
    AgentAccountClean public account;

    address public owner = address(0x1);
    address public sessionKey = address(0x2);
    address public apiProvider = address(0x3);
    address public attacker = address(0x4);

    uint256 public ownerPrivateKey = 0x1;
    uint256 public sessionKeyPrivateKey = 0x2;

    function setUp() public {
        plugin = new SessionKeyPlugin();
        account = new AgentAccountClean(owner);
        
        // Initialize plugin for owner
        vm.prank(owner);
        address[] memory sessionKeys = new address[](1);
        sessionKeys[0] = sessionKey;
        plugin.onInstall(abi.encode(sessionKeys));
    }

    // ============ INITIALIZATION TESTS ============

    function testOnInstall() public {
        address newAccount = address(0x5);
        
        vm.prank(newAccount);
        address[] memory sessionKeys = new address[](1);
        sessionKeys[0] = sessionKey;
        plugin.onInstall(abi.encode(sessionKeys));

        assertTrue(plugin.isInitialized(newAccount));
        assertTrue(plugin.authorizedSessionKeys(newAccount, sessionKey));
    }

    function testModuleType() public {
        assertEq(plugin.moduleType(), 1); // Validator type
    }

    // ============ SESSION KEY MANAGEMENT TESTS ============

    function testAddSessionKey() public {
        address newSessionKey = address(0x6);
        
        vm.prank(owner);
        plugin.addSessionKey(newSessionKey);

        assertTrue(plugin.authorizedSessionKeys(owner, newSessionKey));
    }

    function testRevokeSessionKey() public {
        vm.prank(owner);
        plugin.revokeSessionKey(sessionKey);

        assertFalse(plugin.authorizedSessionKeys(owner, sessionKey));
    }

    // ============ INTENT AUTHORIZATION TESTS ============

    function testAuthorizeIntent() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        bytes32 returnedHash = plugin.authorizeIntent(intent);

        assertEq(returnedHash, intentHash);
    }

    function testCannotAuthorizeExpiredIntent() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp - 1),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        vm.expectRevert(SessionKeyPlugin.IntentExpired.selector);
        plugin.authorizeIntent(intent);
    }

    // ============ INTENT VALIDATION TESTS ============

    function testValidateIntent() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        plugin.authorizeIntent(intent);

        bool valid = plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            0.5 ether
        );

        assertTrue(valid);
    }

    function testCannotExceedPriceCeiling() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        plugin.authorizeIntent(intent);

        vm.expectRevert(SessionKeyPlugin.PriceCeilingExceeded.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            2 ether
        );
    }

    function testCannotSendToNonWhitelistedRecipient() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        plugin.authorizeIntent(intent);

        vm.expectRevert(SessionKeyPlugin.RecipientNotWhitelisted.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            attacker,
            0.5 ether
        );
    }

    // ============ HELPER FUNCTIONS ============

    function _createIntent(
        address account,
        address _sessionKey,
        address[] memory whitelist,
        uint256 priceCeiling,
        uint48 expiry,
        uint256 nonce
    ) internal pure returns (SessionKeyPlugin.IntentMandate memory) {
        return SessionKeyPlugin.IntentMandate({
            account: account,
            sessionKey: _sessionKey,
            whitelist: whitelist,
            priceCeiling: priceCeiling,
            expiry: expiry,
            nonce: nonce,
            signature: ""
        });
    }

    function _createWhitelist(address recipient) 
        internal 
        pure 
        returns (address[] memory) 
    {
        address[] memory whitelist = new address[](1);
        whitelist[0] = recipient;
        return whitelist;
    }

    function _signIntent(bytes32 intentHash, uint256 privateKey) 
        internal 
        pure 
        returns (bytes memory) 
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, intentHash);
        return abi.encodePacked(r, s, v);
    }
}
