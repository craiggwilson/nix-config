# Capacity Planning

## Key Metrics

| Metric | Description |
|--------|-------------|
| Throughput | Requests/second |
| Latency | Response time |
| Utilization | Resource usage % |
| Saturation | Queue depth |
| Headroom | Available capacity |

## Capacity Estimation

```
Required Capacity = Peak Load × Safety Factor

Example:
- Average: 1000 req/s
- Peak: 3000 req/s (3x average)
- Safety factor: 1.5
- Required: 3000 × 1.5 = 4500 req/s capacity
```

## Load Testing for Capacity

```javascript
// k6 stress test
export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '2m', target: 300 },
    { duration: '2m', target: 400 },
    { duration: '2m', target: 500 },  // Find breaking point
  ],
};
```

## Scaling Strategies

### Vertical Scaling
- Increase CPU/memory
- Simple but limited
- Single point of failure

### Horizontal Scaling
- Add more instances
- Requires stateless design
- Better fault tolerance

## Auto-Scaling

```yaml
# Kubernetes HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## Capacity Planning Process

1. **Baseline** - Measure current capacity
2. **Forecast** - Predict future load
3. **Gap Analysis** - Compare capacity vs demand
4. **Plan** - Determine scaling strategy
5. **Implement** - Add capacity
6. **Monitor** - Track utilization

## Warning Signs

| Sign | Action |
|------|--------|
| >70% CPU sustained | Plan scaling |
| >80% memory | Investigate leaks |
| Increasing latency | Profile and optimize |
| Queue buildup | Add capacity |
