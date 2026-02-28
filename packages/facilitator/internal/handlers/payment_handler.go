package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"facilitator/x402"
)

// PaymentHandler handles payment requests
type PaymentHandler struct {
	facilitator *x402.Facilitator
}

// NewPaymentHandler creates a new payment handler
func NewPaymentHandler(facilitator *x402.Facilitator) func(w http.ResponseWriter, r *http.Request) {
	handler := &PaymentHandler{
		facilitator: facilitator,
	}

	return handler.Handle
}

// Handle processes the payment request
func (h *PaymentHandler) Handle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract provider URL from query parameter or header
	providerURL := r.URL.Query().Get("provider")
	if providerURL == "" {
		providerURL = r.Header.Get("X-Provider-URL")
	}

	if providerURL == "" {
		http.Error(w, "Provider URL is required", http.StatusBadRequest)
		return
	}

	// Process payment through the facilitator
	resp, err := h.facilitator.ProcessPayment(providerURL, r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Payment processing failed: %v", err), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Copy response headers
	for key, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}

	// Set response status
	w.WriteHeader(resp.StatusCode)

	// Copy response body
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Failed to read provider response", http.StatusInternalServerError)
		return
	}

	w.Write(responseBody)
}

// VerificationHandler handles verification requests
type VerificationHandler struct {
	facilitator *x402.Facilitator
}

// NewVerificationHandler creates a new verification handler
func NewVerificationHandler(facilitator *x402.Facilitator) func(w http.ResponseWriter, r *http.Request) {
	handler := &VerificationHandler{
		facilitator: facilitator,
	}

	return handler.Handle
}

// Handle processes the verification request
func (h *VerificationHandler) Handle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	providerURL := r.URL.Query().Get("provider")
	if providerURL == "" {
		http.Error(w, "Provider URL is required for verification", http.StatusBadRequest)
		return
	}

	reputation, err := h.facilitator.GetProviderReputation(providerURL)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get provider reputation: %v", err), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"provider":   providerURL,
		"reputation": reputation,
		"timestamp":  r.URL.Query().Get("timestamp"),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
