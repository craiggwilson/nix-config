# Analysis Patterns

## Dependency Analysis

```bash
# Find all imports/requires in a file
rg -n "^(import|from|require|use) " file.ext

# Find circular dependencies (manual trace)
# 1. Find what A imports
rg "^import.*from ['\"]./B" A.ts
# 2. Find what B imports
rg "^import.*from ['\"]./A" B.ts

# Find unused exports
# 1. Find all exports
rg "^export (const|function|class) (\w+)" --type ts -o
# 2. Search for usages of each

# Find dependency graph entry points
rg -l "^import " --type ts | head -20
```

## Call Graph Analysis

```bash
# Find all callers of a function
rg -n "functionName\(" --type ts

# Find all functions called by a function
# Read the function body and extract calls
rg -A 50 "^function targetFunction" file.ts | rg "\w+\("

# Find event handlers
rg -n "addEventListener|on\w+ =" --type ts

# Find callback patterns
rg -n "callback\(|\.then\(|\.catch\(" --type ts
```

## Security Analysis

```bash
# Find hardcoded secrets
rg -i "(password|secret|api_key|token)\s*=\s*['\"][^'\"]+['\"]"

# Find SQL injection risks
rg "execute\(.*\+|query\(.*\+|f\".*SELECT"

# Find command injection risks
rg "exec\(|system\(|subprocess\.call\(.*\+"

# Find eval usage
rg "eval\(|exec\(|Function\("

# Find insecure random
rg "Math\.random|random\.random\(\)"

# Find HTTP (not HTTPS)
rg "http://" --glob "!*.md"

# Find TODO/FIXME security items
rg -i "TODO.*security|FIXME.*security|XXX.*security"
```

## Performance Analysis

```bash
# Find N+1 query patterns
rg "for.*in.*:|\.forEach\(" -A 5 | rg "\.find\(|\.get\(|SELECT"

# Find synchronous file operations
rg "readFileSync|writeFileSync" --type ts

# Find blocking operations
rg "sleep\(|time\.sleep|Thread\.sleep" 

# Find missing indexes (look for queries)
rg "WHERE.*=" --type sql

# Find large loops
rg "for.*range\(.*\d{4,}" --type py
```

## Architecture Discovery

```bash
# Find entry points
fd "main\.(go|py|rs|ts|js)$"
fd "index\.(ts|js)$"
fd "app\.(py|rb)$"

# Find configuration files
fd "\.(yaml|yml|json|toml|ini)$" --max-depth 2

# Find API definitions
fd "openapi|swagger" -e yaml -e json
fd "\.proto$"

# Find database schemas
fd "schema\.(sql|rb|py)$"
fd "migration" -t d

# Find test directories
fd -t d "test|spec|__tests__"

# Find documentation
fd "README|CONTRIBUTING|ARCHITECTURE" -e md
```

## Code Quality

```bash
# Find TODO/FIXME comments
rg -i "TODO|FIXME|XXX|HACK"

# Find long functions (lines after function def)
rg -n "^(def|func|function) " -A 100 | rg -c "."

# Find deeply nested code
rg "^\s{16,}" --type py

# Find duplicate code patterns
rg -c "pattern" | sort -t: -k2 -rn | head

# Find commented-out code
rg "^//.*function|^#.*def |^//.*class"
```

## Git Integration

```bash
# Find recently changed files
git log --oneline --name-only -20 | rg "^\w" | sort -u

# Find files changed by author
git log --author="name" --name-only --oneline | rg "^\w" | sort -u

# Find hotspots (frequently changed)
git log --name-only --oneline -100 | rg "^\w" | sort | uniq -c | sort -rn | head

# Find files with most contributors
git shortlog -sn -- "*.go" | head
```
