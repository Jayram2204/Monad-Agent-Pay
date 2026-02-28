.PHONY: install test build deploy clean

# Install dependencies
install:
	forge install

# Run tests
test:
	forge test -vvv

# Run tests with gas reporting
test-gas:
	forge test --gas-report

# Build contracts
build:
	forge build

# Deploy to Monad Testnet
deploy-monad:
	forge script script/Deploy.s.sol:Deploy \
		--rpc-url monad_testnet \
		--broadcast \
		--verify

# Deploy to local Anvil
deploy-local:
	forge script script/Deploy.s.sol:Deploy \
		--rpc-url http://localhost:8545 \
		--broadcast

# Clean build artifacts
clean:
	forge clean

# Format code
fmt:
	forge fmt

# Run static analysis
analyze:
	slither .

# Generate gas snapshot
snapshot:
	forge snapshot
