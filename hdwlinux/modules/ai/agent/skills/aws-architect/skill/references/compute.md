# AWS Compute Services

## EC2

### Instance Selection
- **General Purpose (t3, m6i)** - Balanced workloads
- **Compute Optimized (c6i)** - CPU-intensive
- **Memory Optimized (r6i)** - Memory-intensive
- **Storage Optimized (i3)** - High I/O

### Best Practices
- Use Auto Scaling Groups
- Spread across multiple AZs
- Use Spot for fault-tolerant workloads
- Right-size with Compute Optimizer

## Lambda

```yaml
# SAM template
MyFunction:
  Type: AWS::Serverless::Function
  Properties:
    Runtime: python3.11
    Handler: app.handler
    MemorySize: 256
    Timeout: 30
    Environment:
      Variables:
        TABLE_NAME: !Ref MyTable
```

### Best Practices
- Keep functions focused
- Minimize cold starts (provisioned concurrency)
- Use layers for shared code
- Set appropriate timeouts

## ECS/Fargate

```yaml
# Task definition
containerDefinitions:
  - name: app
    image: myapp:latest
    cpu: 256
    memory: 512
    portMappings:
      - containerPort: 8080
    logConfiguration:
      logDriver: awslogs
```

### Best Practices
- Use Fargate for simplicity
- EC2 for cost optimization at scale
- Set resource limits
- Use service discovery

## EKS

- Managed Kubernetes control plane
- Use managed node groups
- Consider Fargate for pods
- Use AWS Load Balancer Controller
- Enable cluster autoscaler
