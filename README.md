# AgentPay

**Payment infrastructure for autonomous AI agents on Monad**

AgentPay enables AI agents to autonomously pay for APIs, data, and services using session-based micro-payments. Built with ERC-7579 modular accounts and optimized for Monad's 10,000 TPS parallel execution engine.

## 🎯 The Problem

AI agents need to call paid APIs but can't:
- Use credit cards (no human intervention)
- Handle traditional payment rails ($0.50 minimums, 2-3% fees)
- Execute micro-payments economically ($0.001 API call + $5 gas fee = impossible)

## 💡 The Solution

AgentPay provides:
- **Session-based payments**: Pre-authorized spending limits for agents
- **Micro-payment economics**: $0.006 gas cost makes $0.001 API calls viable
- **Parallel execution**: Session-sharded storage enables 10,000+ concurrent payments
- **Sub-second finality**: 0.8s confirmation keeps agent workflows smooth

## 🚀 Quick Start

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

## 🏗️ Architecture

### Session-Sharded Storage (Zero-Conflict Parallelism)

```solidity
// Each session has isolated storage
mapping(bytes32 => SessionData) private _sessions;

// Different sessions = different storage slots = zero conflicts
// Monad can execute 10,000+ payments in parallel
```

### ERC-7579 Modular Accounts

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

## 🎨 Usage Example

### Create Agent Account

```solidity
AgentFactory factory = AgentFactory(0x...);
bytes32 salt = factory.generateSalt(owner, 0);
address agent = factory.createAccount(owner, salt);
```

### Create Payment Session

```solidity
AgentAccount account = AgentAccount(payable(agent));

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

## 🔒 Security Features

- **Owner-only session creation**: Only account owner can authorize sessions
- **Spending limits**: Per-session caps prevent overspending
- **Time-bounded sessions**: Automatic expiration
- **Session revocation**: Owner can revoke anytime
- **Module isolation**: Modules can't interfere with session state

## 📦 Project Structure

```
packages/
└── contracts/
    ├── src/
    │   ├── AgentAccount.sol       # ERC-7579 modular account
    │   ├── AgentFactory.sol       # CREATE2 factory
    │   └── interfaces/
    │       ├── IERC7579Account.sol
    │       └── IERC7579Module.sol
    ├── test/
    │   ├── AgentAccount.t.sol     # Account tests
    │   └── AgentFactory.t.sol     # Factory tests
    ├── script/
    │   └── Deploy.s.sol           # Deployment script
    ├── ARCHITECTURE.md            # Technical deep-dive
    ├── DEPLOYMENT.md              # Deployment guide
    └── QUICK_START.md             # 5-minute tutorial
```

## 🧪 Testing

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

## 🌐 Monad Testnet

- **Chain ID**: 10143
- **RPC**: https://testnet.monad.xyz
- **Explorer**: https://explorer.testnet.monad.xyz
- **Faucet**: https://faucet.testnet.monad.xyz
- **Block Time**: 0.8s
- **TPS**: 10,000+

## 🎯 Why Monad?

| Requirement | Monad | Ethereum | Solana |
|-------------|-------|----------|--------|
| **Throughput** | 10,000 TPS ✅ | 15 TPS ❌ | 65,000 TPS ✅ |
| **Finality** | 0.8s ✅ | 12s ❌ | 13s ⚠️ |
| **Gas Fees** | $0.006 ✅ | $2-50 ❌ | $0.0003 ✅ |
| **EVM Compatible** | Yes ✅ | Yes ✅ | No ❌ |
| **Parallel Execution** | Yes ✅ | No ❌ | Yes ✅ |

**Verdict**: Monad is the only chain with high throughput, low fees, fast finality, AND EVM compatibility.

## 🛣️ Roadmap

### Phase 1: Core Infrastructure ✅
- [x] ERC-7579 modular accounts
- [x] Session-based payments
- [x] CREATE2 factory
- [x] Comprehensive tests
- [x] Monad testnet deployment

### Phase 2: SDK & Integration (In Progress)
- [ ] JavaScript/TypeScript SDK
- [ ] API provider integration
- [ ] Demo AI agent
- [ ] Dashboard UI

### Phase 3: Production Features
- [ ] Escrow for proof-of-service
- [ ] Relayer/paymaster for Web2 APIs
- [ ] Multi-chain support
- [ ] Mainnet deployment

## 📚 Documentation

- [Quick Start Guide](./packages/contracts/QUICK_START.md) - Get started in 5 minutes
- [Architecture](./packages/contracts/ARCHITECTURE.md) - Technical deep-dive
- [Deployment Guide](./packages/contracts/DEPLOYMENT.md) - Production deployment
- [ERC-7579 Spec](https://eips.ethereum.org/EIPS/eip-7579) - Modular account standard

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines and submit PRs.

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details

## 🔗 Links

- [Monad](https://monad.xyz)
- [Monad Docs](https://docs.monad.xyz)
- [Monad Discord](https://discord.gg/monad)
- [ERC-7579](https://eips.ethereum.org/EIPS/eip-7579)

## 💬 Support

- GitHub Issues: [Report bugs or request features]
- Discord: [Join our community]
- Twitter: [@AgentPay]

---

Built with ❤️ for the AI agent economy on Monad
