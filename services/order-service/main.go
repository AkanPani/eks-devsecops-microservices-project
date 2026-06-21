package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
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

type ProductServiceResponse struct {
	Service string  `json:"service"`
	Product Product `json:"product"`
}

type CreateOrderRequest struct {
	ProductID    string `json:"product_id"`
	Quantity     int    `json:"quantity"`
	CustomerName string `json:"customer_name"`
}

type Order struct {
	ID           string  `json:"id"`
	ProductID    string  `json:"product_id"`
	ProductName  string  `json:"product_name"`
	Quantity     int     `json:"quantity"`
	CustomerName string  `json:"customer_name"`
	TotalAmount  float64 `json:"total_amount"`
	Status       string  `json:"status"`
	CreatedAtUTC string `json:"created_at_utc"`
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
	orders = make(map[string]Order)

	orderMutex sync.RWMutex

	productServiceURL string
	httpClient        = &http.Client{
		Timeout: 5 * time.Second,
	}
)

func main() {
	port := getEnv("PORT", "8082")
	productServiceURL = getEnv("PRODUCT_SERVICE_URL", "http://localhost:8081")

	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", healthHandler)
	mux.HandleFunc("/readyz", readyHandler)
	mux.HandleFunc("/orders", ordersHandler)
	mux.HandleFunc("/orders/", orderByIDHandler)

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      requestLogger(mux),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	log.Printf("order-service started on port %s", port)
	log.Printf("product-service url: %s", productServiceURL)

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("order-service failed to start: %v", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	response := HealthResponse{
		Service: "order-service",
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

	productServiceHealthy := checkProductServiceHealth()

	response := map[string]interface{}{
		"service":                 "order-service",
		"status":                  "ready",
		"product_service_url":      productServiceURL,
		"product_service_reachable": productServiceHealthy,
		"time_utc":                time.Now().UTC().Format(time.RFC3339),
	}

	if !productServiceHealthy {
		writeJSON(w, http.StatusServiceUnavailable, response)
		return
	}

	writeJSON(w, http.StatusOK, response)
}

func ordersHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		createOrder(w, r)
	case http.MethodGet:
		getAllOrders(w, r)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func createOrder(w http.ResponseWriter, r *http.Request) {
	var request CreateOrderRequest

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	request.ProductID = strings.TrimSpace(request.ProductID)
	request.CustomerName = strings.TrimSpace(request.CustomerName)

	if request.ProductID == "" {
		writeError(w, http.StatusBadRequest, "product_id is required")
		return
	}

	if request.Quantity <= 0 {
		writeError(w, http.StatusBadRequest, "quantity must be greater than zero")
		return
	}

	if request.CustomerName == "" {
		writeError(w, http.StatusBadRequest, "customer_name is required")
		return
	}

	product, err := getProductFromProductService(request.ProductID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err.Error())
		return
	}

	if product.Stock < request.Quantity {
		writeError(w, http.StatusBadRequest, "not enough product stock available")
		return
	}

	order := Order{
		ID:           fmt.Sprintf("ORD-%d", time.Now().UnixNano()),
		ProductID:    product.ID,
		ProductName:  product.Name,
		Quantity:     request.Quantity,
		CustomerName: request.CustomerName,
		TotalAmount:  product.Price * float64(request.Quantity),
		Status:       "CREATED",
		CreatedAtUTC: time.Now().UTC().Format(time.RFC3339),
	}

	orderMutex.Lock()
	orders[order.ID] = order
	orderMutex.Unlock()

	/*
		Later in Phase 3 or Phase 4:
		Here we will send this order event to AWS SQS.

		Example future event:
		{
		  "order_id": "ORD-123",
		  "product_id": "101",
		  "status": "CREATED"
		}
	*/

	response := map[string]interface{}{
		"message": "order created successfully",
		"order":   order,
	}

	writeJSON(w, http.StatusCreated, response)
}

func getAllOrders(w http.ResponseWriter, r *http.Request) {
	orderMutex.RLock()
	defer orderMutex.RUnlock()

	orderList := make([]Order, 0, len(orders))

	for _, order := range orders {
		orderList = append(orderList, order)
	}

	response := map[string]interface{}{
		"service": "order-service",
		"orders":  orderList,
	}

	writeJSON(w, http.StatusOK, response)
}

func orderByIDHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	orderID := strings.TrimPrefix(r.URL.Path, "/orders/")
	orderID = strings.TrimSpace(orderID)

	if orderID == "" {
		writeError(w, http.StatusBadRequest, "order id is required")
		return
	}

	orderMutex.RLock()
	order, exists := orders[orderID]
	orderMutex.RUnlock()

	if !exists {
		writeError(w, http.StatusNotFound, "order not found")
		return
	}

	response := map[string]interface{}{
		"service": "order-service",
		"order":   order,
	}

	writeJSON(w, http.StatusOK, response)
}

func getProductFromProductService(productID string) (Product, error) {
	escapedProductID := url.PathEscape(productID)

	requestURL := fmt.Sprintf(
		"%s/products/%s",
		strings.TrimRight(productServiceURL, "/"),
		escapedProductID,
	)

	response, err := httpClient.Get(requestURL)
	if err != nil {
		return Product{}, fmt.Errorf("failed to call product-service: %v", err)
	}
	defer response.Body.Close()

	if response.StatusCode != http.StatusOK {
		return Product{}, fmt.Errorf("product-service returned status code: %d", response.StatusCode)
	}

	var productResponse ProductServiceResponse

	if err := json.NewDecoder(response.Body).Decode(&productResponse); err != nil {
		return Product{}, fmt.Errorf("failed to decode product-service response: %v", err)
	}

	return productResponse.Product, nil
}

func checkProductServiceHealth() bool {
	requestURL := fmt.Sprintf(
		"%s/healthz",
		strings.TrimRight(productServiceURL, "/"),
	)

	response, err := httpClient.Get(requestURL)
	if err != nil {
		log.Printf("product-service health check failed: %v", err)
		return false
	}
	defer response.Body.Close()

	return response.StatusCode == http.StatusOK
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