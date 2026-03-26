package main
import ("encoding/json"; "io"; "log"; "net/http"; "os")

var pythonURL = os.Getenv("PYTHON_SERVICE_URL")
var juliaURL = os.Getenv("JULIA_SERVICE_URL")
var luaURL = os.Getenv("LUA_SERVICE_URL")

func proxy(target string) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        req, _ := http.NewRequest(r.Method, target+r.URL.Path, r.Body)
        req.Header = r.Header
        resp, err := http.DefaultClient.Do(req)
        if err != nil { http.Error(w, err.Error(), 502); return }
        defer resp.Body.Close()
        w.WriteHeader(resp.StatusCode)
        io.Copy(w, resp.Body)
    }
}

func main() {
    http.HandleFunc("/api/", proxy(pythonURL))
    http.HandleFunc("/julia/", proxy(juliaURL))
    http.HandleFunc("/lua/", proxy(luaURL))
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
    })
    port := os.Getenv("PORT")
    if port == "" {
        port = "8000"
    }
    log.Printf("Starting server on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
