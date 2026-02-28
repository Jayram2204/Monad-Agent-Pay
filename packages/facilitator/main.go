package main

import (
	"log"
	"net/http"
	"os"

	"facilitator/internal/handlers"
	"facilitator/x402"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize the x402 facilitator
	facilitator := x402.NewFacilitator()

	// Register handlers
	http.HandleFunc("/api/v1/pay", handlers.NewPaymentHandler(facilitator))
	http.HandleFunc("/api/v1/verify", handlers.NewVerificationHandler(facilitator))

	log.Printf("Starting x402 Facilitator on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
