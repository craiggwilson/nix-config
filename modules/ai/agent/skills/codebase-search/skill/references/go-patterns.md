# Go Search Patterns

## Definitions

```bash
# Find function definitions
rg -n "^func \w+\(" --type go

# Find method definitions (with receiver)
rg -n "^func \([^)]+\) \w+\(" --type go

# Find interface definitions
rg -n "^type \w+ interface" --type go

# Find struct definitions
rg -n "^type \w+ struct" --type go

# Find constant definitions
rg -n "^const \(" --type go -A 10
rg -n "^const \w+ =" --type go

# Find variable definitions
rg -n "^var \w+ =" --type go
```

## Usages

```bash
# Find all usages of a function
rg -n "functionName\(" --type go

# Find interface implementations (methods on type)
rg -n "^func \(.*\*?TypeName\)" --type go

# Find imports of a package
rg -n '"github.com/org/repo/pkg"' --type go

# Find all files importing a package
rg -l '"github.com/org/repo/pkg"' --type go
```

## Patterns

```bash
# Find error handling patterns
rg -n "if err != nil" --type go

# Find goroutine launches
rg -n "go func\(" --type go

# Find channel operations
rg -n "<-\s*\w+|(\w+)\s*<-" --type go

# Find defer statements
rg -n "defer " --type go

# Find panic/recover
rg -n "panic\(|recover\(\)" --type go

# Find context usage
rg -n "context\.Context|ctx\." --type go
```

## Entry Points

```bash
# Find main functions
rg -n "^func main\(\)" --type go

# Find HTTP handlers
rg -n "http\.Handle|mux\.Handle|router\.(GET|POST|PUT|DELETE)" --type go

# Find CLI commands
rg -n "cobra\.Command|cli\.Command" --type go

# Find init functions
rg -n "^func init\(\)" --type go
```

## Testing

```bash
# Find test functions
rg -n "^func Test" --type go

# Find benchmark functions
rg -n "^func Benchmark" --type go

# Find test files
fd "_test.go"

# Find table-driven tests
rg -n "tests := \[\]struct" --type go
```

## Dependencies

```bash
# View go.mod dependencies
cat go.mod | rg "^\t" | head -20

# Find require block
rg "require \(" go.mod -A 50 | rg "^\t"

# Find replace directives
rg "^replace " go.mod
```
