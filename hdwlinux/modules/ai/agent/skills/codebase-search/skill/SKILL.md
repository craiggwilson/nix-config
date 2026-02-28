---
name: codebase-search
description: Search patterns and techniques for codebase analysis. Provides ripgrep patterns, AST analysis approaches, and dependency tracing methods for understanding codebases.
---

# Codebase Search Skill

This skill provides search patterns, commands, and techniques for analyzing codebases. Use these patterns when investigating code structure, tracing dependencies, or understanding system behavior.

## Search Tools

### ripgrep (rg) - Primary Search Tool

ripgrep is the recommended tool for code search due to its speed and smart defaults (respects .gitignore, skips binary files).

**Basic syntax:**
```bash
rg [OPTIONS] PATTERN [PATH...]
```

**Common options:**
| Option | Description |
|:-------|:------------|
| `-n` | Show line numbers (default) |
| `-i` | Case-insensitive search |
| `-w` | Match whole words only |
| `-l` | List files with matches only |
| `-c` | Count matches per file |
| `-A N` | Show N lines after match |
| `-B N` | Show N lines before match |
| `-C N` | Show N lines of context |
| `--type` | Filter by file type |
| `--glob` | Filter by glob pattern |
| `-e` | Multiple patterns (OR) |
| `--pcre2` | Enable PCRE2 regex |

---

## Language-Specific Search Patterns

### Go

```bash
# Find function definitions
rg -n "^func \w+\(" --type go

# Find method definitions (with receiver)
rg -n "^func \([^)]+\) \w+\(" --type go

# Find interface definitions
rg -n "^type \w+ interface" --type go

# Find struct definitions
rg -n "^type \w+ struct" --type go

# Find interface implementations (methods on type)
rg -n "^func \(.*\*?TypeName\)" --type go

# Find all usages of a function
rg -n "functionName\(" --type go

# Find imports of a package
rg -n '"github.com/org/repo/pkg"' --type go

# Find error handling patterns
rg -n "if err != nil" --type go

# Find goroutine launches
rg -n "go func\(" --type go

# Find channel operations
rg -n "<-\s*\w+|(\w+)\s*<-" --type go
```

### Java

```bash
# Find class definitions
rg -n "^public (abstract |final )?class \w+" --type java

# Find interface definitions
rg -n "^public interface \w+" --type java

# Find method definitions
rg -n "^\s+(public|private|protected).*\w+\s*\([^)]*\)\s*(\{|throws)" --type java

# Find interface implementations
rg -n "implements \w+" --type java

# Find class extensions
rg -n "extends \w+" --type java

# Find annotations
rg -n "^@\w+" --type java

# Find Spring beans
rg -n "@(Component|Service|Repository|Controller|Bean)" --type java

# Find dependency injection
rg -n "@(Autowired|Inject)" --type java

# Find test methods
rg -n "@Test" --type java
```

### Python

```bash
# Find class definitions
rg -n "^class \w+" --type py

# Find function definitions
rg -n "^def \w+" --type py

# Find method definitions (indented)
rg -n "^\s+def \w+" --type py

# Find async functions
rg -n "^async def \w+" --type py

# Find decorators
rg -n "^@\w+" --type py

# Find imports
rg -n "^(from|import) " --type py

# Find type hints
rg -n "def \w+\([^)]*:\s*\w+" --type py

# Find dataclasses
rg -n "@dataclass" --type py

# Find pytest fixtures
rg -n "@pytest.fixture" --type py
```

### TypeScript/JavaScript

```bash
# Find function declarations
rg -n "^(export )?(async )?function \w+" --type ts --type js

# Find arrow function assignments
rg -n "^(export )?(const|let|var) \w+ = (async )?\(" --type ts --type js

# Find class definitions
rg -n "^(export )?(abstract )?class \w+" --type ts --type js

# Find interface definitions (TypeScript)
rg -n "^(export )?interface \w+" --type ts

# Find type definitions (TypeScript)
rg -n "^(export )?type \w+ =" --type ts

# Find React components
rg -n "^(export )?(const|function) \w+.*: (React\.)?FC" --type ts --type tsx

# Find imports
rg -n "^import .* from" --type ts --type js

# Find exports
rg -n "^export (default |{)" --type ts --type js
```

### Rust

```bash
# Find function definitions
rg -n "^pub (async )?fn \w+" --type rust

# Find struct definitions
rg -n "^pub struct \w+" --type rust

# Find enum definitions
rg -n "^pub enum \w+" --type rust

# Find trait definitions
rg -n "^pub trait \w+" --type rust

# Find trait implementations
rg -n "^impl \w+ for \w+" --type rust

# Find macro definitions
rg -n "^macro_rules! \w+" --type rust

# Find derive macros
rg -n "#\[derive\(" --type rust

# Find unsafe blocks
rg -n "unsafe \{" --type rust
```

### Ruby

```bash
# Find class definitions
rg -n "^class \w+" --type ruby

# Find module definitions
rg -n "^module \w+" --type ruby

# Find method definitions
rg -n "^\s*def \w+" --type ruby

# Find class methods
rg -n "^\s*def self\.\w+" --type ruby

# Find attr_accessor/reader/writer
rg -n "attr_(accessor|reader|writer)" --type ruby

# Find Rails model associations
rg -n "(has_many|has_one|belongs_to|has_and_belongs_to_many)" --type ruby

# Find Rails callbacks
rg -n "(before_|after_)(action|create|update|save|destroy)" --type ruby

# Find RSpec describe blocks
rg -n "^(RSpec\.)?describe " --type ruby
```

---

## Dependency Analysis

### Finding Dependencies

```bash
# Go modules
cat go.mod | rg "^\t" | head -20
rg "require \(" go.mod -A 50 | rg "^\t"

# Node.js
cat package.json | jq '.dependencies, .devDependencies'

# Python (requirements.txt)
cat requirements.txt

# Python (pyproject.toml)
rg "dependencies" pyproject.toml -A 20

# Rust
rg "^\[dependencies\]" Cargo.toml -A 50

# Java (Maven)
rg "<dependency>" pom.xml -A 4

# Java (Gradle)
rg "(implementation|api|compile)" build.gradle
```

### Tracing Internal Dependencies

```bash
# Find all files importing a module
rg -l "import.*ModuleName" --type py

# Find all files using a package
rg -l '"github.com/org/repo/pkg"' --type go

# Find circular dependency candidates (files that import each other)
# Step 1: Find what file A imports
rg "^import" fileA.py
# Step 2: Check if those files import fileA
rg -l "import.*fileA" 
```

---

## Call Graph Analysis

### Finding Callers

```bash
# Find all callers of a function
rg -n "functionName\(" --type go

# Find callers with context
rg -n -B 5 "functionName\(" --type go

# Find callers in specific directory
rg -n "functionName\(" ./services/
```

### Finding Callees

```bash
# Find what a function calls (read the function body)
rg -n "^func functionName" --type go -A 50

# Find method calls on a type
rg -n "variableName\.\w+\(" --type go
```

---

## Configuration Analysis

```bash
# Find all config files
fd -e yaml -e yml -e json -e toml -e ini

# Find environment variable usage
rg "os\.Getenv|os\.LookupEnv" --type go
rg "process\.env\." --type ts --type js
rg "os\.environ" --type py
rg "ENV\[" --type ruby

# Find config key usage
rg "config\." --type-add 'cfg:*.{yaml,yml,json,toml}'
rg "viper\.(Get|Set)" --type go

# Find feature flags
rg "(feature|flag|toggle)" -i
```

---

## Test Analysis

```bash
# Find all test files
fd -e test.go -e _test.go
fd -e test.ts -e spec.ts -e test.js -e spec.js
fd -e test.py -e _test.py
fd -e _spec.rb -e _test.rb

# Find test functions
rg -n "^func Test" --type go
rg -n "(describe|it|test)\(" --type ts --type js
rg -n "^def test_" --type py
rg -n "^(RSpec\.)?describe" --type ruby

# Find test coverage gaps (functions without tests)
# Step 1: List all functions
rg -n "^func \w+" --type go -l > functions.txt
# Step 2: List all test files
fd "_test.go" > tests.txt
# Step 3: Compare coverage manually

# Find skipped tests
rg -n "(t\.Skip|\.skip\(|@pytest\.mark\.skip|xit\(|xdescribe\()" 

# Find test fixtures
rg -n "@pytest\.fixture" --type py
rg -n "beforeEach|afterEach|beforeAll|afterAll" --type ts --type js
```

---

## Git History Mining

```bash
# Find commits touching a file
git log --oneline -- path/to/file

# Find commits by message pattern
git log --oneline --grep="pattern"

# Find commits changing a function
git log -p -S "functionName" -- "*.go"

# Find who last modified each line
git blame path/to/file

# Find when a line was introduced
git log -p -S "specific code line"

# Find commits between dates
git log --oneline --since="2024-01-01" --until="2024-06-01"

# Find large commits (potential refactors)
git log --oneline --shortstat | head -100
```

---

## Architecture Discovery Patterns

### Finding Entry Points

```bash
# HTTP handlers (Go)
rg -n "http\.Handle|mux\.Handle|router\.(GET|POST|PUT|DELETE)" --type go

# HTTP handlers (Express/Node)
rg -n "app\.(get|post|put|delete|patch)\(" --type ts --type js

# HTTP handlers (FastAPI/Flask)
rg -n "@app\.(get|post|put|delete|patch)" --type py

# Main functions
rg -n "^func main\(\)" --type go
rg -n "if __name__ == .__main__.:" --type py

# CLI commands
rg -n "cobra\.Command|cli\.Command" --type go
rg -n "@click\.command" --type py
```

### Finding Service Boundaries

```bash
# gRPC service definitions
rg -n "^service \w+ \{" --glob "*.proto"

# REST API routes
rg -n "(GET|POST|PUT|DELETE|PATCH)" --glob "*.yaml" --glob "*.yml"

# Message queue consumers
rg -n "Subscribe|Consume|OnMessage" 

# Database connections
rg -n "sql\.Open|pgx\.Connect|mongo\.Connect"
```

---

## Performance Investigation

```bash
# Find potential N+1 queries
rg -n "for .* range|\.forEach\(|for .* in" -A 5 | rg -n "\.Find|\.Query|SELECT"

# Find unbounded queries
rg -n "SELECT \* FROM" --glob "*.sql" --glob "*.go" --glob "*.py"

# Find missing indexes (look for WHERE clauses)
rg -n "WHERE.*=" --glob "*.sql"

# Find goroutine leaks (go without sync)
rg -n "go func\(" --type go -A 10 | rg -v "wg\.|sync\."

# Find blocking operations
rg -n "time\.Sleep|Thread\.sleep" 
```

---

## Security Patterns

```bash
# Find hardcoded secrets (potential)
rg -n "(password|secret|api_key|apikey|token)\s*[:=]" -i

# Find SQL injection risks
rg -n "fmt\.Sprintf.*SELECT|f\"SELECT.*{" 

# Find command injection risks
rg -n "exec\.Command|subprocess\.(run|call|Popen)|system\(" 

# Find insecure random
rg -n "math/rand|Math\.random\(\)" 

# Find disabled TLS verification
rg -n "InsecureSkipVerify|verify=False|NODE_TLS_REJECT_UNAUTHORIZED"
```

---

## Output Formats

### Machine-Readable Output

```bash
# JSON output
rg -n --json "pattern" 

# Files only (for piping)
rg -l "pattern" | xargs ...

# Count only
rg -c "pattern" | sort -t: -k2 -n -r
```

### Filtering Results

```bash
# Exclude directories
rg -n "pattern" --glob "!vendor/*" --glob "!node_modules/*"

# Include only specific paths
rg -n "pattern" --glob "src/**/*.go"

# Exclude test files
rg -n "pattern" --glob "!*_test.go" --glob "!*.test.ts"
```

---

## Best Practices

1. **Start broad, then narrow**: Begin with simple patterns, add specificity as needed
2. **Use file type filters**: `--type go` is faster than searching all files
3. **Exclude generated code**: Use `--glob "!generated/*"` or similar
4. **Combine with fd**: Use `fd` for finding files, `rg` for searching content
5. **Save common searches**: Create shell aliases for frequent patterns
6. **Use context**: `-C 5` shows surrounding code for understanding
7. **Verify with reading**: Search results are starting points; read the actual code
