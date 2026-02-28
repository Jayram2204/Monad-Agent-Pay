# AgentPay Deployment Checklist

Use this checklist to ensure successful deployment to Monad Testnet.

## Pre-Deployment

### Environment Setup
- [ ] Foundry installed (`forge --version`)
- [ ] Git repository initialized
- [ ] `.env` file created from `.env.example`
- [ ] Private key added to `.env` (NEVER commit this!)
- [ ] `.gitignore` configured to exclude `.env`

### Wallet Preparation
- [ ] Wallet address confirmed: `cast wallet address --private-key $PRIVATE_KEY`
- [ ] Testnet MON obtained from faucet: https://faucet.testnet.monad.xyz
- [ ] Balance verified: `cast balance <YOUR_ADDRESS> --rpc-url https://testnet.monad.xyz`
- [ ] Minimum 1 MON available for deployment

### Code Verification
- [ ] All tests passing: `forge test`
- [ ] Gas report reviewed: `forge test --gas-report`
- [ ] No compiler warnings: `forge build`
- [ ] Code formatted: `forge fmt`

## Deployment

### Deploy Contracts
- [ ] Run deployment script:
  ```bash
  forge script script/Deploy.s.sol:Deploy \
    --rpc-url https://testnet.monad.xyz \
    --broadcast \
    --legacy
  ```
- [ ] Deployment successful (no errors)
- [ ] Transaction hash saved
- [ ] Factory address saved: `0x...`
- [ ] Sample account address saved: `0x...`

### Verify Deployment
- [ ] Factory contract visible on explorer: https://explorer.testnet.monad.xyz/address/<FACTORY_ADDRESS>
- [ ] Sample account visible on explorer: https://explorer.testnet.monad.xyz/address/<ACCOUNT_ADDRESS>
- [ ] Factory `accountCount` is 1: `cast call <FACTORY> "accountCount()(uint256)" --rpc-url https://testnet.monad.xyz`
- [ ] Account owner is correct: `cast call <ACCOUNT> "owner()(address)" --rpc-url https://testnet.monad.xyz`

## Post-Deployment Testing

### Create Test Session
- [ ] Fund account with 1 MON:
  ```bash
  cast send <ACCOUNT_ADDRESS> \
    --value 1ether \
    --rpc-url https://testnet.monad.xyz \
    --private-key $PRIVATE_KEY \
    --legacy
  ```
- [ ] Account balance confirmed: `cast balance <ACCOUNT_ADDRESS> --rpc-url https://testnet.monad.xyz`
- [ ] Create test session:
  ```bash
  cast send <ACCOUNT_ADDRESS> \
    "createSession(address,uint256,uint48)" \
    <API_PROVIDER_ADDRESS> \
    1000000000000000000 \
    86400 \
    --rpc-url https://testnet.monad.xyz \
    --private-key $PRIVATE_KEY \
    --legacy
  ```
- [ ] Session ID extracted from transaction logs
- [ ] Session data verified: `cast call <ACCOUNT> "getSession(bytes32)" <SESSION_ID> --rpc-url https://testnet.monad.xyz`

### Execute Test Payment
- [ ] Execute test payment:
  ```bash
  cast send <ACCOUNT_ADDRESS> \
    "executeSessionPayment(bytes32,address,uint256)" \
    <SESSION_ID> \
    <API_PROVIDER_ADDRESS> \
    10000000000000000 \
    --rpc-url https://testnet.monad.xyz \
    --private-key $PRIVATE_KEY \
    --legacy
  ```
- [ ] Payment successful (transaction confirmed)
- [ ] API provider received funds: `cast balance <API_PROVIDER> --rpc-url https://testnet.monad.xyz`
- [ ] Session spent amount updated: `cast call <ACCOUNT> "getSession(bytes32)" <SESSION_ID> --rpc-url https://testnet.monad.xyz`

## Documentation

### Save Deployment Info
- [ ] Create `deployments.json`:
  ```json
  {
    "monad_testnet": {
      "chainId": 10143,
      "factory": "0x...",
      "sampleAccount": "0x...",
      "deployer": "0x...",
      "deployedAt": "2026-02-28T...",
      "txHash": "0x..."
    }
  }
  ```
- [ ] Update README with deployed addresses
- [ ] Commit deployment info to git (NOT private keys!)

### Share with Team
- [ ] Factory address shared
- [ ] Explorer links shared
- [ ] Deployment guide shared
- [ ] API integration docs updated

## Security Review

### Access Control
- [ ] Only deployer can create sessions on sample account
- [ ] Session limits enforced (test with exceeding limit)
- [ ] Session expiration works (test with expired session)
- [ ] Session revocation works (test revoking and using)

### Gas Optimization
- [ ] Session payment gas < 90,000
- [ ] Account creation gas < 1,300,000
- [ ] No unnecessary storage reads
- [ ] Parallel execution tested (multiple sessions)

## Production Readiness

### Before Mainnet
- [ ] All tests passing on testnet
- [ ] Gas costs acceptable
- [ ] Security audit completed (if applicable)
- [ ] Multi-sig owner configured (if applicable)
- [ ] Emergency pause mechanism tested (if applicable)
- [ ] Monitoring/alerting setup
- [ ] Incident response plan documented

### Mainnet Deployment
- [ ] Mainnet RPC configured
- [ ] Mainnet funds available
- [ ] Deployment script tested on testnet
- [ ] Team notified of deployment window
- [ ] Rollback plan documented
- [ ] Post-deployment verification plan ready

## Troubleshooting

### Common Issues

**"Insufficient funds for gas"**
- [ ] Check balance: `cast balance <YOUR_ADDRESS> --rpc-url https://testnet.monad.xyz`
- [ ] Get more from faucet: https://faucet.testnet.monad.xyz

**"Transaction reverted"**
- [ ] Using `--legacy` flag?
- [ ] Correct contract address?
- [ ] Correct function signature?
- [ ] Sufficient gas limit?

**"Nonce too high"**
- [ ] Check current nonce: `cast nonce <YOUR_ADDRESS> --rpc-url https://testnet.monad.xyz`
- [ ] Wait for pending transactions to confirm
- [ ] Reset nonce if stuck

**"Contract not found"**
- [ ] Verify deployment transaction confirmed
- [ ] Check explorer for contract address
- [ ] Ensure using correct RPC URL

## Sign-Off

- [ ] Deployment completed by: _______________
- [ ] Date: _______________
- [ ] Verified by: _______________
- [ ] Date: _______________

## Notes

```
Add any deployment-specific notes here:
- Special configurations
- Known issues
- Performance observations
- Next steps
```

---

**Remember**: NEVER commit private keys or sensitive data to git!
