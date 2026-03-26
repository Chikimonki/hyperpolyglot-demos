package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
)

var pythonServiceURL = getEnv("PYTHON_SERVICE_URL", "http://localhost:8080")

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func proxyToPython(w http.ResponseWriter, r *http.Request) {
	targetURL := pythonServiceURL + r.URL.Path
	proxyReq, err := http.NewRequest(r.Method, targetURL, r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	proxyReq.Header = r.Header
	client := &http.Client{}
	resp, err := client.Do(proxyReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	resp, err := http.Get(pythonServiceURL + "/health")
	pythonHealthy := err == nil && resp.StatusCode == 200
	status := map[string]interface{}{
		"service": "go-gateway",
		"status":  "healthy",
		"backend": map[string]bool{"python": pythonHealthy},
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"service":   "Polyglot Cloud Gateway",
		"stack":     "Go → Python → Zig",
		"endpoints": "/api/fibonacci/:n, /api/primes (POST)",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/", rootHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/api/", proxyToPython)
	port := getEnv("PORT", "8000")
	log.Printf("Go Gateway starting on port %s", port)
	log.Printf("Proxying to Python service at %s", pythonServiceURL)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
