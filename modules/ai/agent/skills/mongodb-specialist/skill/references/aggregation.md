# MongoDB Aggregation

## Pipeline Stages

```javascript
db.orders.aggregate([
  // Filter early
  { $match: { status: "completed" } },
  
  // Reshape documents
  { $project: { 
    user_id: 1, 
    total: 1,
    year: { $year: "$created_at" }
  }},
  
  // Group and aggregate
  { $group: {
    _id: { user_id: "$user_id", year: "$year" },
    totalSpent: { $sum: "$total" },
    orderCount: { $sum: 1 }
  }},
  
  // Sort results
  { $sort: { totalSpent: -1 } },
  
  // Limit output
  { $limit: 10 }
])
```

## Common Stages

| Stage | Purpose |
|-------|---------|
| `$match` | Filter documents |
| `$project` | Reshape documents |
| `$group` | Aggregate by key |
| `$sort` | Order results |
| `$limit` | Limit results |
| `$skip` | Skip results |
| `$unwind` | Flatten arrays |
| `$lookup` | Join collections |

## Lookup (Join)

```javascript
db.orders.aggregate([
  { $lookup: {
    from: "users",
    localField: "user_id",
    foreignField: "_id",
    as: "user"
  }},
  { $unwind: "$user" },
  { $project: {
    total: 1,
    userName: "$user.name"
  }}
])
```

## Window Functions

```javascript
db.sales.aggregate([
  { $setWindowFields: {
    partitionBy: "$region",
    sortBy: { date: 1 },
    output: {
      runningTotal: {
        $sum: "$amount",
        window: { documents: ["unbounded", "current"] }
      },
      movingAvg: {
        $avg: "$amount",
        window: { documents: [-2, 0] }
      }
    }
  }}
])
```

## Optimization Tips

- `$match` early to reduce documents
- Use indexes for `$match` and `$sort`
- `$project` to reduce document size
- Avoid `$unwind` on large arrays
- Use `allowDiskUse` for large datasets
