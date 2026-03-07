# AWS Data Services

## RDS

### Engine Selection
- **PostgreSQL/MySQL** - General purpose
- **Aurora** - High performance, auto-scaling
- **Aurora Serverless** - Variable workloads

### Best Practices
- Multi-AZ for high availability
- Read replicas for read scaling
- Enable automated backups
- Use Parameter Groups for tuning
- Enable Performance Insights

## DynamoDB

### Key Design
```
PK: USER#<user_id>
SK: ORDER#<order_id>

# Access patterns:
# Get user: PK = USER#123
# Get user orders: PK = USER#123, SK begins_with ORDER#
```

### Best Practices
- Design for access patterns
- Use GSIs sparingly
- Enable auto-scaling
- Use DAX for caching
- Enable point-in-time recovery

## S3

### Storage Classes
| Class | Use Case |
|-------|----------|
| Standard | Frequent access |
| Intelligent-Tiering | Unknown patterns |
| Standard-IA | Infrequent access |
| Glacier | Archive |

### Best Practices
- Enable versioning
- Use lifecycle policies
- Block public access by default
- Enable server-side encryption
- Use VPC endpoints

## ElastiCache

### Redis vs Memcached
- **Redis** - Persistence, complex data types, pub/sub
- **Memcached** - Simple caching, multi-threaded

### Best Practices
- Use cluster mode for scaling
- Enable Multi-AZ
- Set appropriate eviction policies
- Monitor memory usage
