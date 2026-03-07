# Alerting

## Alert Design Principles

### Alert on Symptoms, Not Causes
```yaml
# Bad - alerting on cause
- alert: HighCPU
  expr: cpu_usage > 90

# Good - alerting on symptom
- alert: HighLatency
  expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1
```

### Actionable Alerts
Every alert should have:
- Clear description
- Runbook link
- Severity level
- Owner/team

## Prometheus Alerting Rules

```yaml
groups:
  - name: api-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) 
          / sum(rate(http_requests_total[5m])) > 0.01
        for: 5m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"
          runbook_url: "https://wiki/runbooks/high-error-rate"

      - alert: SLOBudgetBurn
        expr: |
          (1 - (sum(rate(http_requests_total{status!~"5.."}[1h])) 
          / sum(rate(http_requests_total[1h])))) > (1 - 0.999) * 14.4
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "SLO budget burning too fast"
```

## Severity Levels

| Severity | Response | Example |
|----------|----------|---------|
| Critical | Page immediately | Service down |
| Warning | Review soon | Degraded performance |
| Info | Review daily | Capacity planning |

## Runbook Template

```markdown
# Alert: HighErrorRate

## Summary
Error rate exceeds 1% threshold.

## Impact
Users experiencing failures.

## Investigation
1. Check error logs: `kubectl logs -l app=api`
2. Check recent deployments
3. Check downstream dependencies

## Remediation
1. Rollback if recent deployment
2. Scale up if capacity issue
3. Escalate to on-call if unclear

## Escalation
- Primary: #backend-oncall
- Secondary: @backend-lead
```

## Alert Fatigue Prevention

- Set appropriate thresholds
- Use `for` duration to avoid flapping
- Group related alerts
- Review and tune regularly
- Delete unused alerts
