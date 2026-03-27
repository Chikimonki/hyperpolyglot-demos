#!/usr/bin/env python3
"""
PolyRaft Cluster Monitor Dashboard
Real-time visualization of cluster state
"""

import json
import time
import requests
import os
from datetime import datetime

# Configuration
NODES = {
    "coordinator": "http://localhost:5000",
    "aggregator": "http://localhost:5002", 
    "consensus": "http://localhost:5003",
}

def clear_screen():
    os.system('clear' if os.name != 'nt' else 'cls')

def get_node_status(name, url):
    try:
        response = requests.get(f"{url}/health", timeout=1)
        data = response.json()
        return {
            "status": "🟢 ONLINE",
            "data": data
        }
    except:
        return {
            "status": "🔴 OFFLINE",
            "data": None
        }

def get_cluster_status():
    try:
        response = requests.get(f"{NODES['coordinator']}/status", timeout=1)
        return response.json()
    except:
        return None

def display_dashboard():
    clear_screen()
    
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║           🚀 POLYRAFT CLUSTER MONITOR                        ║")
    print("║     Distributed Polyglot Consensus System                     ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print()
    
    # Node status
    print("┌─────────────────────────────────────────────────────────────────┐")
    print("│ NODE STATUS                                                     │")
    print("├─────────────────────────────────────────────────────────────────┤")
    
    for name, url in NODES.items():
        status = get_node_status(name, url)
        lang = {
            "coordinator": "Go",
            "aggregator": "Julia",
            "consensus": "LuaJIT"
        }.get(name, "Unknown")
        
        print(f"│ {status['status']} {name:15} ({lang:8}) @ {url:25} │")
        
        if status['data']:
            for key, val in status['data'].items():
                if key not in ['service']:
                    print(f"│    └─ {key}: {val}")
    
    print("└─────────────────────────────────────────────────────────────────┘")
    print()
    
    # Cluster status
    cluster = get_cluster_status()
    if cluster:
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ CLUSTER STATUS                                                  │")
        print("├─────────────────────────────────────────────────────────────────┤")
        print(f"│ Term: {cluster.get('term', 'N/A'):5}  Leader: {cluster.get('leader_id', 'None'):20}   │")
        print(f"│ Nodes: {cluster.get('node_count', 0)}                                                     │")
        print("└─────────────────────────────────────────────────────────────────┘")
    
    print()
    print(f"Last updated: {datetime.now().strftime('%H:%M:%S')}")
    print("Press Ctrl+C to exit")

def main():
    print("Starting PolyRaft Monitor...")
    print("Connecting to cluster nodes...")
    time.sleep(1)
    
    while True:
        try:
            display_dashboard()
            time.sleep(2)  # Refresh every 2 seconds
        except KeyboardInterrupt:
            print("\n\n👋 Monitor stopped. Goodbye!")
            break

if __name__ == "__main__":
    main()

echo "✅ Python dashboard created!"
