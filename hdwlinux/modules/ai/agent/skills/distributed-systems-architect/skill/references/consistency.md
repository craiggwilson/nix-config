# Consistency Models

## CAP Theorem

You can only have 2 of 3:
- **Consistency** - All nodes see same data
- **Availability** - Every request gets a response
- **Partition Tolerance** - System works despite network failures

In practice, P is required, so choose between C and A.

## Consistency Levels

| Level | Description |
|-------|-------------|
| Strong | All reads see latest write |
| Eventual | Reads eventually see latest write |
| Causal | Causally related operations ordered |
| Read-your-writes | Client sees own writes |

## Eventual Consistency

```
Write to Node A ──▶ Replicate ──▶ Node B
                         │
                         ▼
                    Eventually
                    consistent
```

### Handling Conflicts
- Last-write-wins (LWW)
- Vector clocks
- CRDTs (Conflict-free Replicated Data Types)

## Strong Consistency

### Two-Phase Commit
```
Coordinator: PREPARE ──▶ All participants
             ◀── VOTE (yes/no)
             COMMIT ──▶ All participants
             ◀── ACK
```

### Consensus (Raft/Paxos)
- Leader election
- Log replication
- Majority agreement

## Choosing Consistency

| Use Case | Consistency |
|----------|-------------|
| Financial transactions | Strong |
| Social media feeds | Eventual |
| Shopping cart | Session/Causal |
| Inventory counts | Strong or compensating |
