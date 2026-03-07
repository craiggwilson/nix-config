# Database Indexing

## Index Types

| Type | Use Case |
|------|----------|
| B-tree | Default, range queries, sorting |
| Hash | Equality comparisons only |
| GIN | Full-text search, arrays, JSONB |
| GiST | Geometric, full-text |
| BRIN | Large sequential data |

## When to Index

- Primary keys (automatic)
- Foreign keys
- Columns in WHERE clauses
- Columns in JOIN conditions
- Columns in ORDER BY

## Compound Indexes

```sql
-- Order matters!
CREATE INDEX idx_users_status_created 
ON users(status, created_at);

-- Supports:
-- WHERE status = 'active'
-- WHERE status = 'active' AND created_at > '2024-01-01'

-- Does NOT support:
-- WHERE created_at > '2024-01-01' (without status)
```

## Covering Indexes

```sql
-- Include columns to avoid table lookup
CREATE INDEX idx_users_email_include 
ON users(email) INCLUDE (name, created_at);

-- Query uses index only
SELECT name, created_at FROM users WHERE email = 'test@example.com';
```

## Partial Indexes

```sql
-- Index only active users
CREATE INDEX idx_active_users 
ON users(email) WHERE status = 'active';
```

## Index Maintenance

```sql
-- Check index usage
SELECT indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes;

-- Rebuild index
REINDEX INDEX idx_users_email;

-- Remove unused indexes
DROP INDEX idx_unused;
```
