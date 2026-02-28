# AgentPay Quick Start

Get up and running with AgentPay in 5 minutes.

## 1. Install & Test (2 minutes)

```bash
cd packages/contracts
forge install
forge test
```

Expected output: `20 tests passed`

## 2. Deploy to Monad Testnet (2 minutes)

```bash
# Setup
cp .env.example .env
# Edit .env and add your PRIVATE_KEY

# Get testnet funds
# Visit: https://faucet.testnet.monad.xyz

# Deploy
forge script script/Deploy.s.sol:Deploy \
  --rpc-url https://testnet.monad.xyz \
  --broadcast \
  --legacy
```

Save the deployed addresses!

## 3. Create Your First Agent (1 minute)

```bash
# Set variables
FACTORY=0x...  # Your deployed factory address
OWNER=0x...    # Your wallet address

# Create agent account
cast send $FACTORY \
  "createAccount(address,bytes32)" \
  $OWNER \
  0x0000000000000000000000000000000000000000000000000000000000000001 \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy

# Get the agent address from transaction logs
```

## 4. Fund & Create Session

```bash
AGENT=0x...  # Your agent account address
API_PROVIDER=0x...  # API provider address

# Fund agent
cast send $AGENT \
  --value 1ether \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy

# Create session (1 ETH limit, 24 hours)
cast send $AGENT \
  "createSession(address,uint256,uint48)" \
  $API_PROVIDER \
  1000000000000000000 \
  86400 \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy
```

## 5. Execute Payment

```bash
SESSION_ID=0x...  # From createSession transaction logs

# Pay 0.01 ETH to API provider
cast send $AGENT \
  "executeSessionPayment(bytes32,address,uint256)" \
  $SESSION_ID \
  $API_PROVIDER \
  10000000000000000 \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy
```

## Common Commands

### Check Agent Balance
```bash
cast balance $AGENT --rpc-url https://testnet.monad.xyz
```

### Get Session Info
```bash
cast call $AGENT \
  "getSession(bytes32)(address,uint256,uint256,uint48,bool)" \
  $SESSION_ID \
  --rpc-url https://testnet.monad.xyz
```

### Revoke Session
```bash
cast send $AGENT \
  "revokeSession(bytes32)" \
  $SESSION_ID \
  --rpc-url https://testnet.monad.xyz \
  --private-key $PRIVATE_KEY \
  --legacy
```

## Troubleshooting

**"Insufficient funds"**
→ Get testnet MON: https://faucet.testnet.monad.xyz

**"Transaction reverted"**
→ Add `--legacy` flag (Monad doesn't support EIP-1559)

**"Nonce too high"**
→ Check nonce: `cast nonce $OWNER --rpc-url https://testnet.monad.xyz`

## Next Steps

- Read [ARCHITECTURE.md](./ARCHITECTURE.md) for technical details
- Read [DEPLOYMENT.md](./DEPLOYMENT.md) for production deployment
- Build SDK integration (coming soon)
- Create demo AI agent

## Resources

- Monad Testnet Explorer: https://explorer.testnet.monad.xyz
- Monad Docs: https://docs.monad.xyz
- Monad Discord: https://discord.gg/monad
- ERC-7579 Spec: https://eips.ethereum.org/EIPS/eip-7579
