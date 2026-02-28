# x402 Facilitator

The x402 Facilitator is a Go-based service that handles HTTP 402 Payment Required headers and manages payments between clients and service providers.

## Features

- Parses HTTP 402 Payment Required headers
- Verifies PAYMENT-SIGNATURE headers to ensure payment authenticity
- Implements reputation tracking for service providers using a weighted moving average
- Provides API endpoints for payment processing and verification

## Architecture

The facilitator consists of:

1. **Main Service** (`main.go`): Entry point that initializes the facilitator and sets up HTTP routes
2. **x402 Package** (`x402/facilitator.go`): Core logic for handling payment headers and verification
3. **Handlers** (`internal/handlers/`): HTTP request handlers for payment and verification endpoints

## Smart Contracts

The facilitator works with two Solidity smart contracts:

1. **AgentEscrow.sol**: Locks funds until successful service delivery is verified
2. **ReputationLedger.sol**: Tracks provider quality using a weighted moving average

## API Endpoints

- `POST /api/v1/pay?provider=<provider_url>`: Process payments to a service provider
- `GET /api/v1/verify?provider=<provider_url>`: Get provider reputation score

## Usage

1. Start the facilitator:
```bash
cd packages/facilitator
go run main.go
```

2. The service will start on port 8080 (or PORT environment variable)

## Payment Flow

1. Client makes request through facilitator to service provider
2. If provider responds with HTTP 402, facilitator parses payment headers
3. Facilitator verifies the payment signature
4. If verification succeeds, payment is processed and service is delivered
5. Provider reputation is updated based on service outcome

## Reputation System

The reputation system uses a weighted moving average formula:
```
R(t) = α * S(t) + (1 - α) * R(t-1)
```

Where:
- R(t) is the new reputation at time t
- α is the learning rate (how much weight to give to the latest observation)
- S(t) is the current success (1 for success, 0 for failure)
- R(t-1) is the previous reputation

The learning rate adapts based on provider history - newer providers have more volatile reputations while established providers have more stable reputations.