# Database Schema Design

## Normalization Levels

| Form | Rule | Example |
|------|------|---------|
| 1NF | Atomic values, no repeating groups | Split comma-separated values |
| 2NF | No partial dependencies | Move to separate table |
| 3NF | No transitive dependencies | Remove derived data |

## When to Denormalize

- Read-heavy workloads
- Reporting/analytics
- Caching frequently joined data
- Reducing join complexity

## Common Patterns

### One-to-Many
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10,2)
);
```

### Many-to-Many
```sql
CREATE TABLE users (id SERIAL PRIMARY KEY);
CREATE TABLE roles (id SERIAL PRIMARY KEY);

CREATE TABLE user_roles (
    user_id INTEGER REFERENCES users(id),
    role_id INTEGER REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);
```

### Soft Deletes
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    deleted_at TIMESTAMP NULL
);

-- Query active users
SELECT * FROM users WHERE deleted_at IS NULL;
```

### Audit Columns
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by INTEGER,
    updated_by INTEGER
);
```
