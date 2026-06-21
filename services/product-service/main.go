package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

type Product struct {
	ID    string  `json:"id"`
	Name  string  `json:"name"`
	Price float64 `json:"price"`
	Stock int     `json:"stock"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}

type HealthResponse struct {
	Service string `json:"service"`
	Status  string `json:"status"`
	TimeUTC string `json:"time_utc"`
}

var (
	products = map[string]Product{
		"101": {
			ID:    "101",
			Name:  "Laptop",
			Price: 55000,
			Stock: 20,
		},
		"102": {
			ID:    "102",
			Name:  "Keyboard",
			Price: 1200,
			Stock: 50,
		},
		"103": {
			ID:    "103",
			Name:  "Mouse",
			Price: 700,
			Stock: 80,
		},
	}

	productMutex sync.RWMutex
)

func main() {
	port := getEnv("PORT", "8081")

	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", healthHandler)
	mux.HandleFunc("/readyz", readyHandler)
	mux.HandleFunc("/products", productsHandler)
	mux.HandleFunc("/products/", productByIDHandler)

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      requestLogger(mux),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	log.Printf("product-service started on port %s", port)

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("product-service failed to start: %v", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	response := HealthResponse{
		Service: "product-service",
		Status:  "ok",
		TimeUTC: time.Now().UTC().Format(time.RFC3339),
	}

	writeJSON(w, http.StatusOK, response)
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	productMutex.RLock()
	totalProducts := len(products)
	productMutex.RUnlock()

	response := map[string]interface{}{
		"service":        "product-service",
		"status":         "ready",
		"total_products": totalProducts,
		"time_utc":       time.Now().UTC().Format(time.RFC3339),
	}

	writeJSON(w, http.StatusOK, response)
}

func productsHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		getAllProducts(w, r)
	case http.MethodPost:
		createProduct(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func getAllProducts(w http.ResponseWriter, r *http.Request) {
	productMutex.RLock()
	defer productMutex.RUnlock()

	productList := make([]Product, 0, len(products))

	for _, product := range products {
		productList = append(productList, product)
	}

	response := map[string]interface{}{
		"service":  "product-service",
		"products": productList,
	}

	writeJSON(w, http.StatusOK, response)
}

func createProduct(w http.ResponseWriter, r *http.Request) {
	var product Product

	if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if strings.TrimSpace(product.Name) == "" {
		writeError(w, http.StatusBadRequest, "product name is required")
		return
	}

	if product.Price <= 0 {
		writeError(w, http.StatusBadRequest, "product price must be greater than zero")
		return
	}

	if product.Stock < 0 {
		writeError(w, http.StatusBadRequest, "product stock cannot be negative")
		return
	}

	if strings.TrimSpace(product.ID) == "" {
		product.ID = fmt.Sprintf("%d", time.Now().UnixNano())
	}

	productMutex.Lock()
	products[product.ID] = product
	productMutex.Unlock()

	response := map[string]interface{}{
		"message": "product created successfully",
		"product": product,
	}

	writeJSON(w, http.StatusCreated, response)
}

func productByIDHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	productID := strings.TrimPrefix(r.URL.Path, "/products/")
	productID = strings.TrimSpace(productID)

	if productID == "" {
		writeError(w, http.StatusBadRequest, "product id is required")
		return
	}

	productMutex.RLock()
	product, exists := products[productID]
	productMutex.RUnlock()

	if !exists {
		writeError(w, http.StatusNotFound, "product not found")
		return
	}

	response := map[string]interface{}{
		"service": "product-service",
		"product": product,
	}

	writeJSON(w, http.StatusOK, response)
}

func requestLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()

		next.ServeHTTP(w, r)

		log.Printf(
			"method=%s path=%s duration=%s",
			r.Method,
			r.URL.Path,
			time.Since(startTime),
		)
	})
}

func writeJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		log.Printf("failed to write json response: %v", err)
	}
}

func writeError(w http.ResponseWriter, statusCode int, message string) {
	writeJSON(w, statusCode, ErrorResponse{
		Error: message,
	})
}

func getEnv(key string, fallback string) string {
	value := os.Getenv(key)

	if strings.TrimSpace(value) == "" {
		return fallback
	}

	return value
}