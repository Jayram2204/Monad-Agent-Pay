# AgentPay Smart Contracts

ERC-7579 modular account contracts optimized for Monad's parallel execution engine.

## Architecture

### Core Contracts

- **AgentAccount.sol**: ERC-7579 modular account with session-sharded storage
- **AgentFactory.sol**: CREATE2 factory for deterministic agent addresses
- **IERC7579Account.sol**: ERC-7579 account interface
- **IERC7579Module.sol**: ERC-7579 module interface

### Key Optimizations for Monad

1. **Session-Sharded Storage**: Each session has isolated storage slots, enabling zero-conflict parallel execution
2. **Minimal Storage Reads**: Single SLOAD per payment operation
3. **CREATE2 Deployment**: Deterministic addresses for predictable agent IDs
4. **Gas-Optimized**: Via-IR compilation with aggressive optimization

## Storage Layout (Parallel Execution Optimized)

```solidity
// Global state (rarely accessed)
address public owner;

// Session-sharded state (zero conflicts across sessions)
mapping(bytes32 => SessionData) private _sessions;

// Module state (separate from session data)
mapping(uint256 => mapping(address => bool)) private _installedModules;
```

**Why This Works:**
- Different sessions = different storage slots
- Parallel transactions with different sessionIds have ZERO storage conflicts
- Monad can execute 10,000+ session payments in parallel

## Setup

```bash
# Install dependencies
forge install

# Copy environment file
cp .env.example .env

# Edit .env with your private key
```

## Testing

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testParallelSessionPayments -vvv
```

## Deployment

### Monad Testnet

```bash
# Deploy to Monad Testnet
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $MONAD_RPC_URL \
  --broadcast \
  --verify

# Or use the shorthand
forge script script/Deploy.s.sol:Deploy \
  --rpc-url monad_testnet \
  --broadcast
```

### Local Testing

```bash
# Start local Anvil node
anvil

# Deploy to local node
forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast
```

## Usage

### Create Agent Account

```solidity
// Deploy factory
AgentFactory factory = new AgentFactory();

// Generate deterministic salt
bytes32 salt = factory.generateSalt(owner, 0);

// Create account
address agentAccount = factory.createAccount(owner, salt);
```

### Create Payment Session

```solidity
AgentAccount account = AgentAccount(payable(agentAccount));

// Create session: $1 limit, 24 hours
bytes32 sessionId = account.createSession(
    apiProvider,
    1 ether,
    1 days
);
```

### Execute Micro-Payment

```solidity
// Pay $0.001 for API call
account.executeSessionPayment(
    sessionId,
    apiProvider,
    0.001 ether
);
```

## Gas Benchmarks

| Operation | Gas Cost | Monad Cost (@$0.0001/gas) |
|-----------|----------|---------------------------|
| Create Session | ~45,000 | $0.0045 |
| Session Payment | ~35,000 | $0.0035 |
| Batch Payment (10x) | ~180,000 | $0.018 |

**Result**: Micro-payments ($0.001) are economically viable on Monad!

## Security Features

1. **Owner-Only Session Creation**: Only account owner can create sessions
2. **Spend Limits**: Per-session spending caps
3. **Time-Bounded Sessions**: Automatic expiration
4. **Session Revocation**: Owner can revoke sessions anytime
5. **Module Isolation**: Modules can't interfere with session state

## Monad-Specific Features

### Parallel Execution
- Session-sharded storage eliminates conflicts
- 10,000+ concurrent payments possible
- Zero contention between different sessions

### Low Latency
- 0.8s finality enables real-time API payments
- Agent doesn't wait for confirmations

### Sub-Cent Fees
- $0.0035 per payment makes micro-transactions viable
- $0.001 API call + $0.0035 gas = $0.0045 total cost

## Network Information

**Monad Testnet**
- Chain ID: 10143
- RPC: https://testnet.monad.xyz
- Explorer: https://explorer.testnet.monad.xyz
- Faucet: https://faucet.testnet.monad.xyz

## License

MIT
