# MongoDB Operations

## Replication

```javascript
// Replica set configuration
rs.initiate({
  _id: "myReplicaSet",
  members: [
    { _id: 0, host: "mongo1:27017", priority: 2 },
    { _id: 1, host: "mongo2:27017", priority: 1 },
    { _id: 2, host: "mongo3:27017", priority: 1 }
  ]
})

// Check status
rs.status()

// Add member
rs.add("mongo4:27017")
```

## Read/Write Concerns

```javascript
// Write concern
db.orders.insertOne(
  { item: "widget" },
  { writeConcern: { w: "majority", j: true } }
)

// Read concern
db.orders.find().readConcern("majority")

// Read preference
db.orders.find().readPref("secondaryPreferred")
```

## Sharding

```javascript
// Enable sharding on database
sh.enableSharding("mydb")

// Shard collection
sh.shardCollection("mydb.orders", { user_id: "hashed" })

// Check sharding status
sh.status()
```

### Shard Key Selection

| Key Type | Use Case |
|----------|----------|
| Hashed | Even distribution |
| Ranged | Range queries |
| Compound | Multiple access patterns |

## Backup and Restore

```bash
# Backup
mongodump --uri="mongodb://localhost:27017" --out=/backup

# Restore
mongorestore --uri="mongodb://localhost:27017" /backup

# Point-in-time recovery (with oplog)
mongodump --oplog --out=/backup
mongorestore --oplogReplay /backup
```

## Monitoring

```javascript
// Server status
db.serverStatus()

// Current operations
db.currentOp()

// Profiler
db.setProfilingLevel(1, { slowms: 100 })
db.system.profile.find().sort({ ts: -1 }).limit(10)
```

## Atlas Operations

- Automated backups
- Performance Advisor
- Real-time metrics
- Auto-scaling
- Global clusters
