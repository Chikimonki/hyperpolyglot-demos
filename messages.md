# PolyRaft Protocol Specification

## Message Types

### 1. Heartbeat
```json
{
  "type": "heartbeat",
  "from": "node_id",
  "term": 1,
  "timestamp": 1234567890
}
