# Query Optimization

## EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT u.name, COUNT(o.id)
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active'
GROUP BY u.id;
```

## Reading Query Plans

| Operation | Meaning |
|-----------|---------|
| Seq Scan | Full table scan (often bad) |
| Index Scan | Using index (good) |
| Index Only Scan | Using covering index (best) |
| Nested Loop | Join method for small sets |
| Hash Join | Join method for larger sets |
| Sort | Sorting (check for index) |

## Common Optimizations

### Avoid SELECT *
```sql
-- Bad
SELECT * FROM users;

-- Good
SELECT id, name, email FROM users;
```

### Use EXISTS vs IN
```sql
-- Better for large subqueries
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);
```

### Pagination
```sql
-- Offset pagination (slow for large offsets)
SELECT * FROM users ORDER BY id LIMIT 20 OFFSET 1000;

-- Keyset pagination (fast)
SELECT * FROM users WHERE id > 1000 ORDER BY id LIMIT 20;
```

### CTEs for Readability
```sql
WITH active_users AS (
    SELECT * FROM users WHERE status = 'active'
),
recent_orders AS (
    SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '30 days'
)
SELECT u.name, COUNT(o.id)
FROM active_users u
JOIN recent_orders o ON o.user_id = u.id
GROUP BY u.id;
```
