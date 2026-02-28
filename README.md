AgentPay

Payment infrastructure for autonomous AI agents on Monad**

AgentPay enables AI agents to autonomously pay for APIs, data, and services using session-based micro-payments. Built with ERC-7579 modular accounts and optimized for Monad's 10,000 TPS parallel execution engine.

<img width="1280" height="832" alt="Screenshot 2026-02-28 at 4 20 24 PM" src="https://github.com/user-attachments/assets/17a2f411-81c5-4f8a-b298-500c9fafa0c1" />

🎯 The Problem

AI agents need to call paid APIs but can't:
- Use credit cards (no human intervention)
- Handle traditional payment rails ($0.50 minimums, 2-3% fees)
- Execute micro-payments economically ($0.001 API call + $5 gas fee = impossible)

💡 The Solution

AgentPay provides:
- **Session-based payments**: Pre-authorized spending limits for agents
- **Micro-payment economics**: $0.006 gas cost makes $0.001 API calls viable
- **Parallel execution**: Session-sharded storage enables 10,000+ concurrent payments
- **Sub-second finality**: 0.8s confirmation keeps agent workflows smooth

🚀 Quick Start

```bash
# Clone and install
git clone <repo>
cd packages/contracts
forge install

# Run tests
forge test

# Deploy to Monad Testnet
cp .env.example .env
# Add your PRIVATE_KEY to .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url https://testnet.monad.xyz \
  --broadcast \
  --legacy
```

See [QUICK_START.md](./packages/contracts/QUICK_START.md) for detailed instructions.

## 📊 Gas Benchmarks

| Operation | Gas Cost | Monad Cost (@$0.0001/gas) |
|-----------|----------|---------------------------|
| Create Session | 120,161 | $0.012 |
| Session Payment | 59,886 | $0.006 |
| Batch Payment (3x) | 128,185 | $0.013 |

**Result**: $0.001 API calls are economically viable!

<img width="1274" height="479" alt="Screenshot 2026-02-28 at 4 20 33 PM" src="https://github.com/user-attachments/assets/1deaa259-7dc6-40e8-9cdc-66426d027acf" />

🏗️ Architecture

Session-Sharded Storage (Zero-Conflict Parallelism)

```solidity
// Each session has isolated storage
mapping(bytes32 => SessionData) private _sessions;

// Different sessions = different storage slots = zero conflicts
// Monad can execute 10,000+ payments in parallel
```

ERC-7579 Modular Accounts

```
AgentFactory (CREATE2)
    │
    ├─► AgentAccount #1
    │   ├─ Session A (API Provider 1)
    │   ├─ Session B (API Provider 2)
    │   └─ Modules (validators, executors, hooks)
    │
    ├─► AgentAccount #2
    └─► AgentAccount #3
```

See [ARCHITECTURE.md](./packages/contracts/ARCHITECTURE.md) for technical deep-dive.

<img width="639" height="355" alt="Screenshot 2026-02-28 at 4 22 47 PM" src="https://github.com/user-attachments/assets/1224e649-7a73-45b2-abbd-02b8aaa9cca8" />

🎨 Usage Example

Create Agent Account

```solidity
AgentFactory factory = AgentFactory(0x...);
bytes32 salt = factory.generateSalt(owner, 0);
address agent = factory.createAccount(owner, salt);
```

Create Payment Session

```solidity
AgentAccount account = AgentAccount(payable(agent));

// Create session: $1 limit, 24 hours
bytes32 sessionId = account.createSession(
    apiProvider,
    1 ether,
    1 days
);
```

<img width="637" height="494" alt="Screenshot 2026-02-28 at 4 23 32 PM" src="https://github.com/user-attachments/assets/99276968-30aa-4336-a5df-6b3001928b5e" />

Execute Micro-Payment

```solidity
// Pay $0.001 for API call
account.executeSessionPayment(
    sessionId,
    apiProvider,
    0.001 ether
);
```

🔒 Security Features

- **Owner-only session creation**: Only account owner can authorize sessions
- **Spending limits**: Per-session caps prevent overspending
- **Time-bounded sessions**: Automatic expiration
- **Session revocation**: Owner can revoke anytime
- **Module isolation**: Modules can't interfere with session state

🧪 Testing

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testParallelSessionPayments -vvv

# Generate gas snapshot
forge snapshot
```

All 20 tests pass with comprehensive coverage of:
- Session creation and management
- Payment execution and limits
- Parallel execution scenarios
- Module installation/uninstallation
- Access control and security

<img width="1239" height="384" alt="Screenshot 2026-02-28 at 4 23 44 PM" src="https://github.com/user-attachments/assets/6095d733-a88c-402a-930d-c8c253f78db9" />

🌐 Monad Testnet

- **Chain ID**: 10143
- **RPC**: https://testnet.monad.xyz
- **Explorer**: https://explorer.testnet.monad.xyz
- **Faucet**: https://faucet.testnet.monad.xyz
- **Block Time**: 0.8s
- **TPS**: 10,000+

🎯 Why Monad?

| Requirement | Monad | Ethereum | Solana |
|-------------|-------|----------|--------|
| **Throughput** | 10,000 TPS ✅ | 15 TPS ❌ | 65,000 TPS ✅ |
| **Finality** | 0.8s ✅ | 12s ❌ | 13s ⚠️ |
| **Gas Fees** | $0.006 ✅ | $2-50 ❌ | $0.0003 ✅ |
| **EVM Compatible** | Yes ✅ | Yes ✅ | No ❌ |
| **Parallel Execution** | Yes ✅ | No ❌ | Yes ✅ |

**Verdict**: Monad is the only chain with high throughput, low fees, fast finality, AND EVM compatibility.

🛣️ Roadmap

Phase 1: Core Infrastructure ✅
- [x] ERC-7579 modular accounts
- [x] Session-based payments
- [x] CREATE2 factory
- [x] Comprehensive tests
- [x] Monad testnet deployment

 Phase 2: SDK & Integration (In Progress)
- [ ] JavaScript/TypeScript SDK
- [ ] API provider integration
- [ ] Demo AI agent
- [ ] Dashboard UI

Phase 3: Production Features
- [ ] Escrow for proof-of-service
- [ ] Relayer/paymaster for Web2 APIs
- [ ] Multi-chain support
- [ ] Mainnet deployment

📚 Documentation

- [Quick Start Guide](./packages/contracts/QUICK_START.md) - Get started in 5 minutes
- [Architecture](./packages/contracts/ARCHITECTURE.md) - Technical deep-dive
- [Deployment Guide](./packages/contracts/DEPLOYMENT.md) - Production deployment
- [ERC-7579 Spec](https://eips.ethereum.org/EIPS/eip-7579) - Modular account standard


📄 License

MIT License - see [LICENSE](./LICENSE) for details

🔗 Links

- [Monad](https://monad.xyz)
- [Monad Docs](https://docs.monad.xyz)
- [Monad Discord](https://discord.gg/monad)
- [ERC-7579](https://eips.ethereum.org/EIPS/eip-7579)

