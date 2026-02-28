# SessionKeyPlugin - AP2 Intent Mandates

## Overview

The SessionKeyPlugin is an ERC-7579 validator module that implements **AP2 (AgentPay Protocol v2) Intent Mandates**. It enforces human authorization for all agent-led transactions through cryptographically signed intents.

## Core Concept

**Problem**: AI agents need autonomy but must be constrained by human intent.

**Solution**: Human signs an "Intent Mandate" that specifies:
- Which session key (agent) can act
- Which recipients are approved (whitelist)
- Maximum amount per transaction (price ceiling)
- How long the authorization lasts (expiry)

**Result**: Agent can execute transactions autonomously, but ONLY within human-defined boundaries.

## AP2 Intent Mandate Schema

```solidity
struct IntentMandate {
    address account;           // Account executing the intent
    address sessionKey;        // Authorized session key (agent's key)
    address[] whitelist;       // Approved recipient addresses
    uint256 priceCeiling;      // Maximum amount per transaction
    uint48 expiry;             // Intent expiration timestamp
    uint256 nonce;             // Replay protection nonce
    bytes signature;           // Human's signature (owner)
}
```

### Field Descriptions

#### `account`
- The AgentAccount that will execute transactions
- Must match the account calling `authorizeIntent()`
- Prevents intent from being used by wrong account

#### `sessionKey`
- The address of the agent's signing key
- Must be pre-authorized via `addSessionKey()`
- Agent uses this key to sign transactions

#### `whitelist`
- Array of approved recipient addresses
- Agent can ONLY send funds to these addresses
- Empty array = no recipients allowed (intent is useless)

#### `priceCeiling`
- Maximum amount (in wei) per transaction
- Agent cannot exceed this limit
- Example: `1 ether` = max 1 ETH per transaction

#### `expiry`
- Unix timestamp when intent expires
- Agent cannot use intent after this time
- Uses `uint48` (sufficient until year 8,921,556)

#### `nonce`
- Replay protection counter
- Must match current nonce for account
- Increments after each authorization

#### `signature`
- EIP-712 signature from account owner
- Proves human authorized this intent
- 65 bytes (r, s, v format)

## Security Model

### Three-Layer Protection

1. **Session Key Authorization**
   - Session key must be pre-authorized by owner
   - Owner can revoke session keys anytime
   - Prevents unauthorized agents from acting

2. **Intent Mandate Validation**
   - Every transaction requires a matching intent
   - Intent must be signed by account owner
   - Signature proves human authorization

3. **Transaction Constraints**
   - Recipient must be whitelisted
   - Amount must not exceed price ceiling
   - Intent must not be expired
   - Intent can only be used once

### Attack Prevention

**Scenario 1: Compromised Agent Key**
- Attacker steals agent's session key
- Attacker tries to drain account
- ❌ BLOCKED: Can only send to whitelisted addresses
- ❌ BLOCKED: Cannot exceed price ceiling
- ❌ BLOCKED: Intent expires after set time

**Scenario 2: Malicious Agent**
- Agent tries to send funds to attacker
- ❌ BLOCKED: Recipient not in whitelist
- Agent tries to send large amount
- ❌ BLOCKED: Exceeds price ceiling

**Scenario 3: Replay Attack**
- Attacker captures valid intent signature
- Attacker tries to reuse it
- ❌ BLOCKED: Intent marked as executed
- ❌ BLOCKED: Nonce prevents replay

**Scenario 4: Unauthorized Session Key**
- Attacker creates their own session key
- Attacker tries to use it
- ❌ BLOCKED: Session key not authorized by owner

## Usage Flow

### 1. Setup (One-Time)

```solidity
// Owner installs plugin on their AgentAccount
address[] memory sessionKeys = new address[](1);
sessionKeys[0] = agentSessionKey;
plugin.onInstall(abi.encode(sessionKeys));
```

### 2. Create Intent (Per Task)

```javascript
// Human creates intent for agent task
const intent = {
    account: agentAccountAddress,
    sessionKey: agentSessionKey,
    whitelist: [weatherAPIAddress, imageAPIAddress],
    priceCeiling: ethers.parseEther("0.1"), // Max 0.1 ETH
    expiry: Math.floor(Date.now() / 1000) + 86400, // 24 hours
    nonce: await plugin.nonces(agentAccountAddress),
    signature: "" // Will be filled
};

// Human signs intent (EIP-712)
const intentHash = await plugin.hashIntent(intent);
intent.signature = await owner.signMessage(intentHash);

// Authorize intent on-chain
await plugin.connect(owner).authorizeIntent(intent);
```

### 3. Agent Executes (Autonomous)

```javascript
// Agent executes transaction within intent boundaries
await plugin.validateIntent(
    agentAccountAddress,
    intentHash,
    agentSessionKey,
    weatherAPIAddress,  // Must be in whitelist
    ethers.parseEther("0.01")  // Must be <= priceCeiling
);

// If validation passes, agent can execute payment
```

### 4. Revoke (If Needed)

```solidity
// Owner can revoke intent anytime
plugin.revokeIntent(intentHash);

// Or revoke session key entirely
plugin.revokeSessionKey(agentSessionKey);
```

## EIP-712 Signature

The plugin uses EIP-712 for structured data signing:

```
Domain:
  name: "AgentPay SessionKeyPlugin"
  version: "2"
  chainId: <current chain>
  verifyingContract: <plugin address>

Type:
  IntentMandate(
    address account,
    address sessionKey,
    address[] whitelist,
    uint256 priceCeiling,
    uint48 expiry,
    uint256 nonce
  )
```

This ensures:
- Signatures are chain-specific (prevents cross-chain replay)
- Signatures are contract-specific (prevents cross-contract replay)
- Wallets display human-readable data before signing

## Integration with AgentAccount

### Installation

```solidity
// Install as validator module
agentAccount.installModule(
    1, // MODULE_TYPE_VALIDATOR
    sessionKeyPluginAddress,
    abi.encode(sessionKeys)
);
```

### Transaction Flow

```
1. Human authorizes Intent Mandate
   ↓
2. Agent prepares transaction
   ↓
3. Plugin validates transaction against intent
   ↓
4. If valid: Transaction executes
   If invalid: Transaction reverts
```

## Gas Costs

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Install Plugin | ~100,000 | One-time per account |
| Add Session Key | ~50,000 | Per session key |
| Authorize Intent | ~150,000 | Per intent |
| Validate Intent | ~80,000 | Per transaction |
| Revoke Intent | ~30,000 | If needed |

## Best Practices

### For Humans (Account Owners)

1. **Minimal Whitelist**: Only include necessary recipients
2. **Conservative Price Ceiling**: Set lowest viable amount
3. **Short Expiry**: Use shortest reasonable duration
4. **Monitor Usage**: Check which intents are executed
5. **Revoke Promptly**: Revoke unused intents

### For Agents (AI Systems)

1. **Request Specific Intents**: Ask for exactly what you need
2. **Respect Boundaries**: Never try to bypass constraints
3. **Handle Rejections**: Gracefully handle validation failures
4. **Report Usage**: Log all intent usage for transparency
5. **Request Renewal**: Ask human for new intent when expired

### For Developers

1. **Validate Before Execution**: Always call `validateIntent()` first
2. **Handle Errors**: Catch and handle all revert reasons
3. **Store Intent Hashes**: Keep mapping of tasks to intents
4. **Implement Fallbacks**: Have manual approval flow as backup
5. **Test Thoroughly**: Test all constraint violations

## Example Use Cases

### Use Case 1: Research Agent

```solidity
// Human authorizes research agent
IntentMandate memory intent = IntentMandate({
    account: researchAgentAccount,
    sessionKey: researchAgentKey,
    whitelist: [
        academicPapersAPI,
        dataSourceAPI,
        factCheckingAPI
    ],
    priceCeiling: 0.05 ether, // $0.05 per call
    expiry: block.timestamp + 7 days,
    nonce: 0,
    signature: ownerSignature
});
```

**Result**: Agent can autonomously purchase research data for 7 days, max $0.05 per call, only from approved sources.

### Use Case 2: Trading Agent

```solidity
// Human authorizes trading agent
IntentMandate memory intent = IntentMandate({
    account: tradingAgentAccount,
    sessionKey: tradingAgentKey,
    whitelist: [
        marketDataAPI,
        newsAPI,
        analyticsAPI
    ],
    priceCeiling: 0.01 ether, // $0.01 per call
    expiry: block.timestamp + 1 days,
    nonce: 0,
    signature: ownerSignature
});
```

**Result**: Agent can fetch market data for 24 hours, max $0.01 per call, only from approved APIs.

### Use Case 3: Customer Service Agent

```solidity
// Human authorizes customer service agent
IntentMandate memory intent = IntentMandate({
    account: customerServiceAccount,
    sessionKey: customerServiceKey,
    whitelist: [
        translationAPI,
        sentimentAPI,
        knowledgeBaseAPI
    ],
    priceCeiling: 0.001 ether, // $0.001 per call
    expiry: block.timestamp + 30 days,
    nonce: 0,
    signature: ownerSignature
});
```

**Result**: Agent can handle customer queries for 30 days, max $0.001 per call, only using approved services.

## Comparison: With vs Without Intent Mandates

### Without Intent Mandates (Dangerous)

```solidity
// Agent has full control
agent.execute(anyAddress, anyAmount, anyData);
```

**Risks**:
- Agent can drain entire account
- Agent can send to malicious addresses
- No human oversight
- No spending limits

### With Intent Mandates (Safe)

```solidity
// Agent must validate against intent
plugin.validateIntent(account, intentHash, sessionKey, recipient, amount);
// Only executes if all constraints satisfied
```

**Benefits**:
- Agent constrained by human intent
- Whitelist prevents unauthorized recipients
- Price ceiling prevents overspending
- Expiry limits time window
- Human maintains control

## Security Considerations

### Signature Security

- ✅ Uses EIP-712 for structured signing
- ✅ Includes nonce for replay protection
- ✅ Includes expiry for time-bounding
- ✅ Validates signature on-chain
- ✅ Checks signer is account owner

### Storage Security

- ✅ Intent state isolated per account
- ✅ Executed flag prevents reuse
- ✅ Whitelist stored in mapping (gas-efficient)
- ✅ No external calls during validation
- ✅ No reentrancy vulnerabilities

### Access Control

- ✅ Only owner can authorize intents
- ✅ Only owner can add/revoke session keys
- ✅ Only owner can revoke intents
- ✅ Session keys must be pre-authorized
- ✅ Validation checks all constraints

## Testing

The plugin includes comprehensive tests covering:

- ✅ Initialization and setup
- ✅ Session key management
- ✅ Intent authorization
- ✅ Intent validation
- ✅ Constraint enforcement (whitelist, price ceiling, expiry)
- ✅ Replay protection
- ✅ Signature verification
- ✅ Intent revocation
- ✅ Error handling

Run tests:
```bash
forge test --match-contract SessionKeyPluginTest -vvv
```

## Future Enhancements

### Planned Features

1. **Multi-Use Intents**: Allow N uses instead of single-use
2. **Spending Budgets**: Track total spending across multiple txs
3. **Time Windows**: Allow specific hours/days (e.g., business hours only)
4. **Conditional Logic**: Enable if-then rules (e.g., if price < X, then allow)
5. **Intent Templates**: Pre-defined intent patterns for common use cases

### Potential Integrations

1. **ERC-4337 Bundlers**: Native support for account abstraction
2. **Gasless Transactions**: Paymaster integration for sponsored txs
3. **Cross-Chain Intents**: Use same intent across multiple chains
4. **Oracle Integration**: Dynamic price ceilings based on market data
5. **DAO Governance**: Multi-sig approval for high-value intents

## License

MIT License - see LICENSE file for details

## Support

- GitHub Issues: [Report bugs]
- Discord: [Join community]
- Documentation: [Full docs]
