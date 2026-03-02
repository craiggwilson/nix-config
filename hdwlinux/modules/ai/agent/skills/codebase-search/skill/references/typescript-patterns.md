# TypeScript/JavaScript Search Patterns

## Definitions

```bash
# Find class definitions
rg -n "^(export )?(class|abstract class) \w+" --type ts

# Find function definitions
rg -n "^(export )?(function|async function) \w+" --type ts

# Find arrow function exports
rg -n "^export const \w+ = (async )?\(" --type ts

# Find interface definitions
rg -n "^(export )?interface \w+" --type ts

# Find type definitions
rg -n "^(export )?type \w+ =" --type ts

# Find enum definitions
rg -n "^(export )?enum \w+" --type ts
```

## Usages

```bash
# Find imports
rg -n "^import " --type ts

# Find specific import
rg -n "from ['\"]module['\"]" --type ts

# Find all files importing a module
rg -l "from ['\"]@/components" --type ts

# Find require statements (CommonJS)
rg -n "require\(['\"]" --type ts
```

## Patterns

```bash
# Find React components
rg -n "^(export )?(function|const) \w+.*: (React\.)?FC" --type ts
rg -n "^(export )?function \w+\([^)]*\).*JSX\.Element" --type ts

# Find hooks
rg -n "^(export )?(function|const) use\w+" --type ts

# Find useState/useEffect
rg -n "useState|useEffect|useCallback|useMemo" --type ts

# Find decorators
rg -n "^@\w+" --type ts

# Find async/await
rg -n "async |await " --type ts

# Find Zod schemas
rg -n "z\.(object|string|number|array)" --type ts
```

## Entry Points

```bash
# Find main/index files
fd "index\.(ts|tsx|js|jsx)$"
fd "main\.(ts|tsx|js|jsx)$"

# Find Next.js pages
fd -p "pages/.*\.(tsx|ts)$"
fd -p "app/.*page\.(tsx|ts)$"

# Find API routes
fd -p "api/.*\.(ts|js)$"
rg -n "export (default|async) function (GET|POST|PUT|DELETE)" --type ts

# Find Express routes
rg -n "app\.(get|post|put|delete|patch)\(" --type ts
rg -n "router\.(get|post|put|delete|patch)\(" --type ts
```

## Testing

```bash
# Find test files
fd "\.(test|spec)\.(ts|tsx|js|jsx)$"

# Find test functions
rg -n "(describe|it|test)\(['\"]" --type ts

# Find Jest mocks
rg -n "jest\.mock|vi\.mock" --type ts

# Find test utilities
rg -n "render\(|screen\.|fireEvent\." --type ts
```

## Dependencies

```bash
# View package.json dependencies
cat package.json | jq '.dependencies'
cat package.json | jq '.devDependencies'

# Find all package.json files
fd "package.json"
```
