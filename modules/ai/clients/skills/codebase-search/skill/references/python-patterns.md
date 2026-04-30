# Python Search Patterns

## Definitions

```bash
# Find class definitions
rg -n "^class \w+" --type py

# Find function definitions
rg -n "^def \w+" --type py

# Find method definitions (indented)
rg -n "^\s+def \w+" --type py

# Find async functions
rg -n "^async def \w+" --type py

# Find async methods
rg -n "^\s+async def \w+" --type py

# Find property definitions
rg -n "@property" --type py -A 1
```

## Usages

```bash
# Find imports
rg -n "^(from|import) " --type py

# Find specific import
rg -n "from module import" --type py
rg -n "import module" --type py

# Find all files importing a module
rg -l "from module import|import module" --type py

# Find function calls
rg -n "function_name\(" --type py
```

## Patterns

```bash
# Find decorators
rg -n "^@\w+" --type py

# Find type hints
rg -n "def \w+\([^)]*:\s*\w+" --type py

# Find dataclasses
rg -n "@dataclass" --type py

# Find Pydantic models
rg -n "class \w+\(BaseModel\)" --type py

# Find exception handling
rg -n "except \w+:" --type py

# Find context managers
rg -n "with .* as" --type py
rg -n "@contextmanager" --type py
```

## Entry Points

```bash
# Find main blocks
rg -n "if __name__ == .__main__.:" --type py

# Find FastAPI routes
rg -n "@app\.(get|post|put|delete|patch)" --type py

# Find Flask routes
rg -n "@app\.route" --type py

# Find Django views
rg -n "def \w+\(request" --type py

# Find CLI commands (Click)
rg -n "@click\.command" --type py

# Find Celery tasks
rg -n "@celery\.task|@app\.task" --type py
```

## Testing

```bash
# Find test functions
rg -n "^def test_" --type py

# Find test classes
rg -n "^class Test\w+" --type py

# Find pytest fixtures
rg -n "@pytest\.fixture" --type py

# Find test files
fd "test_*.py"
fd "*_test.py"

# Find skipped tests
rg -n "@pytest\.mark\.skip" --type py
```

## Dependencies

```bash
# View requirements.txt
cat requirements.txt

# Find pyproject.toml dependencies
rg "dependencies" pyproject.toml -A 20

# Find setup.py dependencies
rg "install_requires" setup.py -A 10
```
