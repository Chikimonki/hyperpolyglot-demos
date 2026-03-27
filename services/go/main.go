package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
)

var (
	pythonURL = getEnv("PYTHON_SERVICE_URL", "http://localhost:8080")
	juliaURL  = getEnv("JULIA_SERVICE_URL", "http://localhost:8083")
	luaURL    = getEnv("LUA_SERVICE_URL", "http://localhost:8082")
)

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func enableCORS(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
}

func proxyTo(targetURL string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		enableCORS(w)
		
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		
		target := targetURL + r.URL.Path
		log.Printf("Proxying %s %s -> %s", r.Method, r.URL.Path, target)
		
		proxyReq, err := http.NewRequest(r.Method, target, r.Body)
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
		
		for k, v := range resp.Header {
			w.Header()[k] = v
		}
		
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)
	
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	
	checkService := func(url string) bool {
		resp, err := http.Get(url + "/health")
		return err == nil && resp.StatusCode == 200
	}
	
	status := map[string]interface{}{
		"service": "go-gateway",
		"status":  "healthy",
		"backends": map[string]interface{}{
			"python": map[string]interface{}{
				"url":     pythonURL,
				"healthy": checkService(pythonURL),
			},
			"julia": map[string]interface{}{
				"url":     juliaURL,
				"healthy": checkService(juliaURL),
			},
			"lua": map[string]interface{}{
				"url":     luaURL,
				"healthy": checkService(luaURL),
			},
		},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)
	w.Header().Set("Content-Type", "application/json")
	
	info := map[string]interface{}{
		"service": "Hyperpolyglot Gateway",
		"version": "2.0-cors",
		"stack":   []string{"Go", "Python", "Julia", "LuaJIT", "Zig"},
	}
	
	json.NewEncoder(w).Encode(info)
}

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/api/", proxyTo(pythonURL))
	http.HandleFunc("/julia/", proxyTo(juliaURL))
	http.HandleFunc("/lua/", proxyTo(luaURL))
	http.HandleFunc("/", rootHandler)
	
	port := getEnv("PORT", "8000")
	
	log.Printf("Gateway (CORS enabled) on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
