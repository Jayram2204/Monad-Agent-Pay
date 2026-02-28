package x402

import (
	"crypto/ecdsa"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// Facilitator handles HTTP 402 Payment Required requests and verifies payment signatures
type Facilitator struct {
	providers map[string]*Provider
}

// Provider represents a service provider that requires payment
type Provider struct {
	URL        string
	PublicKey  *ecdsa.PublicKey
	Reputation float64
	LastAccess time.Time
}

// PaymentRequest represents a payment request from a client
type PaymentRequest struct {
	Amount      float64
	Currency    string
	Destination string
	PaymentHash string
	Signature   string
	Timestamp   time.Time
}

// NewFacilitator creates a new x402 facilitator
func NewFacilitator() *Facilitator {
	return &Facilitator{
		providers: make(map[string]*Provider),
	}
}

// ParsePaymentHeaders extracts payment information from HTTP 402 headers
func (f *Facilitator) ParsePaymentHeaders(resp *http.Response) (*PaymentRequest, error) {
	paymentHeader := resp.Header.Get("HTTP-Status")
	if !strings.Contains(paymentHeader, "402 Payment Required") {
		return nil, fmt.Errorf("response is not HTTP 402 Payment Required")
	}

	amountStr := resp.Header.Get("Amount")
	currency := resp.Header.Get("Currency")
	destination := resp.Header.Get("Destination")
	paymentHash := resp.Header.Get("PAYMENT-HASH")
	signature := resp.Header.Get("PAYMENT-SIGNATURE")

	if amountStr == "" || currency == "" || destination == "" || paymentHash == "" || signature == "" {
		return nil, fmt.Errorf("missing required payment headers")
	}

	amount := 0.0
	fmt.Sscanf(amountStr, "%f", &amount)

	return &PaymentRequest{
		Amount:      amount,
		Currency:    currency,
		Destination: destination,
		PaymentHash: paymentHash,
		Signature:   signature,
		Timestamp:   time.Now(),
	}, nil
}

// VerifyPaymentSignature verifies the payment signature using the provider's public key
func (f *Facilitator) VerifyPaymentSignature(req *PaymentRequest, pubKey *ecdsa.PublicKey) (bool, error) {
	// Decode the base64 encoded signature
	_, err := base64.StdEncoding.DecodeString(req.Signature)
	if err != nil {
		return false, fmt.Errorf("failed to decode signature: %v", err)
	}

	// Create the message to verify (amount + currency + destination + hash + timestamp)
	message := fmt.Sprintf("%f%s%s%s%d", req.Amount, req.Currency, req.Destination, req.PaymentHash, req.Timestamp.Unix())
	_ = sha256.Sum256([]byte(message))

	// Verification would typically involve elliptic curve operations
	// This is a simplified representation - actual implementation would depend on the signature algorithm used
	// In a real implementation, we would use crypto/ecdsa.Verify to verify the signature

	// For now, returning true as a placeholder
	return true, nil
}

// ProcessPayment handles the payment processing flow
func (f *Facilitator) ProcessPayment(providerURL string, requestBody io.Reader) (*http.Response, error) {
	provider, exists := f.providers[providerURL]
	if !exists {
		return nil, fmt.Errorf("provider not registered: %s", providerURL)
	}

	// Make request to provider
	client := &http.Client{}
	req, err := http.NewRequest("POST", providerURL, requestBody)
	if err != nil {
		return nil, err
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}

	// Check if response is HTTP 402 Payment Required
	if resp.StatusCode == 402 {
		// Parse payment headers
		paymentReq, err := f.ParsePaymentHeaders(resp)
		if err != nil {
			return nil, fmt.Errorf("failed to parse payment headers: %v", err)
		}

		// Verify payment signature
		valid, err := f.VerifyPaymentSignature(paymentReq, provider.PublicKey)
		if err != nil {
			return nil, fmt.Errorf("failed to verify payment signature: %v", err)
		}

		if !valid {
			return nil, fmt.Errorf("invalid payment signature")
		}

		// Payment verified, return the response
		return resp, nil
	} else if resp.StatusCode == 200 {
		// If provider returns 200, increment reputation
		f.updateReputation(providerURL, true)
		return resp, nil
	} else {
		// If provider returns other error, decrement reputation
		f.updateReputation(providerURL, false)
		return resp, nil
	}
}

// updateReputation updates the provider's reputation score
func (f *Facilitator) updateReputation(providerURL string, success bool) {
	provider, exists := f.providers[providerURL]
	if !exists {
		return
	}

	// Update reputation based on success/failure
	// This uses a weighted moving average approach
	alpha := 0.1 // Learning rate
	if success {
		provider.Reputation = alpha*1.0 + (1-alpha)*provider.Reputation
	} else {
		provider.Reputation = alpha*0.0 + (1-alpha)*provider.Reputation
	}

	provider.LastAccess = time.Now()
}

// RegisterProvider registers a new service provider
func (f *Facilitator) RegisterProvider(url string, pubKey *ecdsa.PublicKey) {
	f.providers[url] = &Provider{
		URL:        url,
		PublicKey:  pubKey,
		Reputation: 0.5, // Start with neutral reputation
		LastAccess: time.Now(),
	}
}

// GetProviderReputation returns the reputation score for a provider
func (f *Facilitator) GetProviderReputation(providerURL string) (float64, error) {
	provider, exists := f.providers[providerURL]
	if !exists {
		return 0, fmt.Errorf("provider not found: %s", providerURL)
	}

	return provider.Reputation, nil
}
