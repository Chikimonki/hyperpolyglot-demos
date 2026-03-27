package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "sync"
    "time"
)

type Node struct {
    ID       string
    Address  string
    State    string
    LastSeen time.Time
}

type Cluster struct {
    mu       sync.RWMutex
    nodes    map[string]*Node
    leaderID string
    term     int
}

var cluster = &Cluster{
    nodes: make(map[string]*Node),
    term:  0,
}

func (c *Cluster) RegisterNode(id, address string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.nodes[id] = &Node{
        ID:       id,
        Address:  address,
        State:    "follower",
        LastSeen: time.Now(),
    }
    log.Printf("Node registered: %s", id)
}

func (c *Cluster) Heartbeat(id string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    if node, ok := c.nodes[id]; ok {
        node.LastSeen = time.Now()
    }
}

func (c *Cluster) GetStatus() map[string]interface{} {
    c.mu.RLock()
    defer c.mu.RUnlock()
    nodeList := make([]map[string]interface{}, 0)
    for _, node := range c.nodes {
        nodeList = append(nodeList, map[string]interface{}{
            "id":      node.ID,
            "address": node.Address,
            "state":   node.State,
            "alive":   time.Since(node.LastSeen) < 5*time.Second,
        })
    }
    return map[string]interface{}{
        "term":       c.term,
        "leader_id":  c.leaderID,
        "nodes":      nodeList,
        "node_count": len(c.nodes),
    }
}

func handleRegister(w http.ResponseWriter, r *http.Request) {
    var req struct {
        ID      string
        Address string
    }
    json.NewDecoder(r.Body).Decode(&req)
    cluster.RegisterNode(req.ID, req.Address)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{"status": "registered"})
}

func handleHeartbeat(w http.ResponseWriter, r *http.Request) {
    var req struct {
        ID string
    }
    json.NewDecoder(r.Body).Decode(&req)
    cluster.Heartbeat(req.ID)
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func handleStatus(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Header().Set("Access-Control-Allow-Origin", "*")
    json.NewEncoder(w).Encode(cluster.GetStatus())
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.Header().Set("Access-Control-Allow-Origin", "*")
    json.NewEncoder(w).Encode(map[string]string{
        "service": "polyraft-coordinator",
        "status":  "healthy",
    })
}

func main() {
    fmt.Println("═══════════════════════════════════════")
    fmt.Println("  PolyRaft Go Coordinator")
    fmt.Println("  Port: 5000")
    fmt.Println("═══════════════════════════════════════")
    
    http.HandleFunc("/register", handleRegister)
    http.HandleFunc("/heartbeat", handleHeartbeat)
    http.HandleFunc("/status", handleStatus)
    http.HandleFunc("/health", handleHealth)
    
    cluster.RegisterNode("go_coordinator", "localhost:5000")
    
    fmt.Println("\nGo coordinator ready!")
    log.Fatal(http.ListenAndServe(":5000", nil))
}
