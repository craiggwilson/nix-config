# Database Migrations

## Zero-Downtime Migrations

### Expand-Contract Pattern

1. **Expand** - Add new column/table
2. **Migrate** - Copy data, update application
3. **Contract** - Remove old column/table

### Adding a Column

```sql
-- Step 1: Add nullable column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Step 2: Backfill data
UPDATE users SET phone = 'unknown' WHERE phone IS NULL;

-- Step 3: Add constraint (after backfill)
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
```

### Renaming a Column

```sql
-- Step 1: Add new column
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);

-- Step 2: Copy data
UPDATE users SET full_name = name;

-- Step 3: Update application to use both
-- Step 4: Stop using old column
-- Step 5: Drop old column
ALTER TABLE users DROP COLUMN name;
```

## Migration Best Practices

- Always test migrations on production-like data
- Make migrations reversible
- Run migrations in transactions
- Avoid long-running locks
- Use `CONCURRENTLY` for index creation

```sql
-- Non-blocking index creation
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

## Migration Tools

| Tool | Language |
|------|----------|
| Flyway | Java |
| Alembic | Python |
| Goose | Go |
| ActiveRecord | Ruby |
| Prisma | TypeScript |
