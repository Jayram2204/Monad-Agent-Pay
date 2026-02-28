# AgentPay Deployment Guide

## Prerequisites

1. **Foundry installed**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Monad Testnet wallet with funds**
   - Get testnet MON from: https://faucet.testnet.monad.xyz
   - Save your private key securely

## Quick Start

### 1. Setup Environment

```bash
cd packages/contracts
cp .env.example .env
```

Edit `.env` and add your private key:
```
PRIVATE_KEY=0x...your_private_key_here
```

### 2. Run Tests

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testParallelSessionPayments -vvv
```

### 3. Deploy to Monad Testnet

```bash
# Deploy contracts
forge script script/Deploy.s.sol:Deploy \
  --rpc-url https://testnet.monad.xyz \
  --broadcast \
  --legacy

# Or use make
make deploy-monad
```

## Deployment Output

After successful deployment, you'll see:

```
=== Deployment Summary ===
Network: Monad Testnet (ChainID: 10143)
AgentFactory: 0x...
Sample AgentAccount: 0x...
Owner: 0x...
```

Save these addresses for your SDK integration!

## Verify Contracts (Optional)

```bash
forge verify-contract \
  --chain-id 10143 \
  --compiler-version v0.8.23 \
  <FACTORY_ADDRESS> \
  src/AgentFactory.sol:AgentFactory
```

## Post-Deployment Testing

### Create an Agent Account

```bash
cast send <FACTORY_ADDRESS> \
  "createAccount(address,bytes32)" \
  <YOUR_ADDRESS> \
  <SALT> \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy
```

### Fund the Account

```bash
cast send <AGENT_ACCOUNT_ADDRESS> \
  --value 1ether \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy
```

### Create a Session

```bash
cast send <AGENT_ACCOUNT_ADDRESS> \
  "createSession(address,uint256,uint48)" \
  <API_PROVIDER_ADDRESS> \
  1000000000000000000 \
  86400 \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy
```

## Gas Costs on Monad

Based on test results:

| Operation | Gas Cost | Monad Cost (@$0.0001/gas) |
|-----------|----------|---------------------------|
| Deploy Factory | 1,767,388 | $0.177 |
| Create Account | ~1,218,812 | $0.122 |
| Create Session | ~120,161 | $0.012 |
| Session Payment | ~59,886 | $0.006 |
| Batch Payment (3x) | ~128,185 | $0.013 |

**Key Insight**: Session payments cost ~$0.006 in gas, making $0.001 API calls economically viable!

## Troubleshooting

### "Insufficient funds" error
- Ensure your wallet has testnet MON
- Get more from: https://faucet.testnet.monad.xyz

### "Nonce too high" error
- Reset your nonce: `cast nonce <YOUR_ADDRESS> --rpc-url https://testnet.monad.xyz`

### "Transaction reverted" error
- Check you're using `--legacy` flag (Monad doesn't support EIP-1559 yet)
- Verify contract addresses are correct

## Network Information

**Monad Testnet**
- Chain ID: 10143
- RPC URL: https://testnet.monad.xyz
- Explorer: https://explorer.testnet.monad.xyz
- Faucet: https://faucet.testnet.monad.xyz
- Block Time: ~0.8s
- TPS: 10,000+

## Next Steps

1. **Integrate with SDK**: Use deployed addresses in your JavaScript/TypeScript SDK
2. **Deploy API Provider Contracts**: Create contracts for API providers to receive payments
3. **Build Demo Agent**: Create an AI agent that uses AgentPay for API calls
4. **Monitor Performance**: Track gas costs and transaction times on Monad

## Security Checklist

- [ ] Private keys stored securely (never commit to git)
- [ ] Factory address saved
- [ ] Sample account address saved
- [ ] Testnet funds available
- [ ] Deployment verified on explorer
- [ ] Session limits configured appropriately
- [ ] Owner address is correct

## Support

- Monad Discord: https://discord.gg/monad
- Monad Docs: https://docs.monad.xyz
- AgentPay Issues: [Your GitHub repo]
