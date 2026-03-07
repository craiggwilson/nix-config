# Kubernetes Troubleshooting

## Pod Issues

```bash
# Get pod status
kubectl get pods -o wide

# Describe pod (events, conditions)
kubectl describe pod <pod-name>

# Get logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container>  # specific container
kubectl logs <pod-name> --previous      # previous instance

# Execute into pod
kubectl exec -it <pod-name> -- /bin/sh
```

## Common Pod States

| State | Cause | Fix |
|-------|-------|-----|
| Pending | No resources | Check node capacity |
| ImagePullBackOff | Image not found | Check image name/registry |
| CrashLoopBackOff | App crashing | Check logs |
| OOMKilled | Out of memory | Increase memory limit |
| Evicted | Node pressure | Check node resources |

## Debugging Commands

```bash
# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods
kubectl top nodes

# Check endpoints
kubectl get endpoints <service>

# DNS debugging
kubectl run debug --image=busybox -it --rm -- nslookup <service>

# Network debugging
kubectl run debug --image=nicolaka/netshoot -it --rm -- bash
```

## Service Issues

```bash
# Check service
kubectl describe service <service>

# Check endpoints
kubectl get endpoints <service>

# Test service from pod
kubectl exec -it <pod> -- curl <service>:<port>
```

## Node Issues

```bash
# Check node status
kubectl get nodes
kubectl describe node <node>

# Check node conditions
kubectl get nodes -o jsonpath='{.items[*].status.conditions}'

# Drain node for maintenance
kubectl drain <node> --ignore-daemonsets
kubectl uncordon <node>
```

## Resource Debugging

```bash
# Get all resources in namespace
kubectl get all -n <namespace>

# Check resource quotas
kubectl describe resourcequota

# Check limit ranges
kubectl describe limitrange
```
