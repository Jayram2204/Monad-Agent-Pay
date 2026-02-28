// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {SessionKeyPlugin} from "../src/modules/SessionKeyPlugin.sol";

contract SessionKeyPluginTest is Test {
    SessionKeyPlugin public plugin;

    address public owner = address(0x1);
    address public sessionKey = address(0x2);
    address public apiProvider = address(0x3);
    address public attacker = address(0x4);

    uint256 public ownerPrivateKey = 0x1;
    uint256 public sessionKeyPrivateKey = 0x2;

    function setUp() public {
        plugin = new SessionKeyPlugin();
        
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

    function testCannotInstallTwice() public {
        vm.prank(owner);
        vm.expectRevert(SessionKeyPlugin.Unauthorized.selector);
        plugin.onInstall("");
    }

    function testOnUninstall() public {
        vm.prank(owner);
        plugin.onUninstall("");

        assertFalse(plugin.isInitialized(owner));
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

    function testCannotAddSessionKeyUnauthorized() public {
        vm.prank(attacker);
        vm.expectRevert(SessionKeyPlugin.Unauthorized.selector);
        plugin.addSessionKey(address(0x7));
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

        // Sign intent with owner's key
        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        bytes32 returnedHash = plugin.authorizeIntent(intent);

        assertEq(returnedHash, intentHash);

        // Verify intent state
        (
            address storedSessionKey,
            uint256 priceCeiling,
            uint48 expiry,
            bool executed
        ) = plugin.getIntent(owner, intentHash);

        assertEq(storedSessionKey, sessionKey);
        assertEq(priceCeiling, 1 ether);
        assertEq(expiry, uint48(block.timestamp + 1 days));
        assertFalse(executed);
    }

    function testCannotAuthorizeExpiredIntent() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp - 1), // Already expired
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        vm.expectRevert(SessionKeyPlugin.IntentExpired.selector);
        plugin.authorizeIntent(intent);
    }

    function testCannotAuthorizeWithInvalidSignature() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        // Sign with wrong key
        intent.signature = _signIntent(intentHash, sessionKeyPrivateKey);

        vm.prank(owner);
        vm.expectRevert(SessionKeyPlugin.InvalidSignature.selector);
        plugin.authorizeIntent(intent);
    }

    function testCannotAuthorizeWithUnauthorizedSessionKey() public {
        address unauthorizedKey = address(0x8);
        
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            unauthorizedKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        vm.expectRevert(SessionKeyPlugin.SessionKeyNotAuthorized.selector);
        plugin.authorizeIntent(intent);
    }

    function testCannotAuthorizeWithWrongNonce() public {
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            999 // Wrong nonce
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        vm.expectRevert(SessionKeyPlugin.InvalidIntentData.selector);
        plugin.authorizeIntent(intent);
    }

    // ============ INTENT VALIDATION TESTS ============

    function testValidateIntent() public {
        // Authorize intent
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

        // Validate transaction
        bool valid = plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            0.5 ether
        );

        assertTrue(valid);

        // Check intent is marked as executed
        (, , , bool executed) = plugin.getIntent(owner, intentHash);
        assertTrue(executed);
    }

    function testCannotValidateWithWrongSessionKey() public {
        // Authorize intent
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

        // Try to validate with wrong session key
        vm.expectRevert(SessionKeyPlugin.SessionKeyNotAuthorized.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            attacker, // Wrong session key
            apiProvider,
            0.5 ether
        );
    }

    function testCannotValidateExpiredIntent() public {
        // Authorize intent with short expiry
        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 hours),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        plugin.authorizeIntent(intent);

        // Fast forward past expiry
        vm.warp(block.timestamp + 2 hours);

        // Try to validate
        vm.expectRevert(SessionKeyPlugin.IntentExpired.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            0.5 ether
        );
    }

    function testCannotExceedPriceCeiling() public {
        // Authorize intent with 1 ETH ceiling
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

        // Try to validate with amount exceeding ceiling
        vm.expectRevert(SessionKeyPlugin.PriceCeilingExceeded.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            2 ether // Exceeds 1 ETH ceiling
        );
    }

    function testCannotSendToNonWhitelistedRecipient() public {
        // Authorize intent with only apiProvider whitelisted
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

        // Try to validate with non-whitelisted recipient
        vm.expectRevert(SessionKeyPlugin.RecipientNotWhitelisted.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            attacker, // Not whitelisted
            0.5 ether
        );
    }

    function testCannotReuseIntent() public {
        // Authorize intent
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

        // First validation succeeds
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            0.5 ether
        );

        // Second validation fails (already used)
        vm.expectRevert(SessionKeyPlugin.IntentAlreadyUsed.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            0.5 ether
        );
    }

    // ============ INTENT REVOCATION TESTS ============

    function testRevokeIntent() public {
        // Authorize intent
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

        // Revoke intent
        vm.prank(owner);
        plugin.revokeIntent(intentHash);

        // Try to validate (should fail)
        vm.expectRevert(SessionKeyPlugin.IntentAlreadyUsed.selector);
        plugin.validateIntent(
            owner,
            intentHash,
            sessionKey,
            apiProvider,
            0.5 ether
        );
    }

    // ============ WHITELIST TESTS ============

    function testMultipleWhitelistedRecipients() public {
        address provider1 = address(0x10);
        address provider2 = address(0x11);
        address provider3 = address(0x12);

        address[] memory whitelist = new address[](3);
        whitelist[0] = provider1;
        whitelist[1] = provider2;
        whitelist[2] = provider3;

        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            whitelist,
            1 ether,
            uint48(block.timestamp + 1 days),
            0
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        plugin.authorizeIntent(intent);

        // Verify all are whitelisted
        assertTrue(plugin.isWhitelisted(owner, intentHash, provider1));
        assertTrue(plugin.isWhitelisted(owner, intentHash, provider2));
        assertTrue(plugin.isWhitelisted(owner, intentHash, provider3));
        assertFalse(plugin.isWhitelisted(owner, intentHash, attacker));
    }

    // ============ NONCE TESTS ============

    function testNonceIncrementsAfterAuthorization() public {
        uint256 initialNonce = plugin.nonces(owner);

        SessionKeyPlugin.IntentMandate memory intent = _createIntent(
            owner,
            sessionKey,
            _createWhitelist(apiProvider),
            1 ether,
            uint48(block.timestamp + 1 days),
            initialNonce
        );

        bytes32 intentHash = plugin.hashIntent(intent);
        intent.signature = _signIntent(intentHash, ownerPrivateKey);

        vm.prank(owner);
        plugin.authorizeIntent(intent);

        assertEq(plugin.nonces(owner), initialNonce + 1);
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
