# Systematic Debugging

## The Scientific Method

1. **Observe** - Gather information about the bug
2. **Hypothesize** - Form a theory about the cause
3. **Predict** - What would confirm/deny the theory?
4. **Test** - Run experiment to test prediction
5. **Iterate** - Refine hypothesis based on results

## Binary Search Debugging

```bash
# Find the commit that introduced the bug
git bisect start
git bisect bad HEAD
git bisect good v1.0.0
# Git checks out middle commit
# Test and mark good/bad
git bisect good  # or git bisect bad
# Repeat until found
```

## Isolation Techniques

### Disable Components
- Comment out code sections
- Disable features with flags
- Use mock implementations
- Remove recent changes

### Minimal Reproduction
1. Start with failing case
2. Remove unrelated code
3. Simplify inputs
4. Create standalone test

## Debugging Questions

- What changed recently?
- When did it last work?
- Can you reproduce it?
- What's different about failing cases?
- What do the logs say?
- What does the error message mean?

## Common Causes

| Symptom | Likely Cause |
|---------|--------------|
| Works locally, fails in prod | Environment difference |
| Intermittent failure | Race condition, timing |
| Slow degradation | Memory leak, resource exhaustion |
| Sudden failure | Deployment, config change |
