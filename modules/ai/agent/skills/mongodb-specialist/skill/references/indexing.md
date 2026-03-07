# MongoDB Indexing

## Index Types

```javascript
// Single field
db.users.createIndex({ email: 1 })

// Compound index
db.orders.createIndex({ user_id: 1, created_at: -1 })

// Multikey (arrays)
db.products.createIndex({ tags: 1 })

// Text index
db.articles.createIndex({ title: "text", content: "text" })

// Geospatial
db.locations.createIndex({ coordinates: "2dsphere" })
```

## ESR Rule (Equality, Sort, Range)

```javascript
// Query: status = "active" AND created_at > date ORDER BY priority
// Index order: Equality, Sort, Range
db.tasks.createIndex({ 
  status: 1,      // Equality first
  priority: 1,    // Sort second
  created_at: 1   // Range last
})
```

## Covered Queries

```javascript
// Index covers all fields in query and projection
db.users.createIndex({ email: 1, name: 1 })

// This query is covered (no document fetch)
db.users.find(
  { email: "test@example.com" },
  { name: 1, _id: 0 }
)
```

## Partial Indexes

```javascript
// Index only active users
db.users.createIndex(
  { email: 1 },
  { partialFilterExpression: { status: "active" } }
)
```

## TTL Indexes

```javascript
// Auto-delete after 24 hours
db.sessions.createIndex(
  { createdAt: 1 },
  { expireAfterSeconds: 86400 }
)
```

## Index Analysis

```javascript
// Explain query
db.users.find({ email: "test@example.com" }).explain("executionStats")

// Check index usage
db.users.aggregate([
  { $indexStats: {} }
])

// List indexes
db.users.getIndexes()
```

## Best Practices

- Create indexes for frequent queries
- Follow ESR rule for compound indexes
- Monitor index size and usage
- Remove unused indexes
- Use partial indexes for filtered queries
