# Java Search Patterns

## Definitions

```bash
# Find class definitions
rg -n "^public (abstract |final )?class \w+" --type java

# Find interface definitions
rg -n "^public interface \w+" --type java

# Find enum definitions
rg -n "^public enum \w+" --type java

# Find method definitions
rg -n "^\s+(public|private|protected).*\w+\s*\(" --type java

# Find record definitions (Java 14+)
rg -n "^public record \w+" --type java

# Find annotation definitions
rg -n "^public @interface \w+" --type java
```

## Usages

```bash
# Find imports
rg -n "^import " --type java

# Find specific import
rg -n "import org\.springframework" --type java

# Find all files importing a package
rg -l "import com\.company\.module" --type java

# Find method calls
rg -n "\.methodName\(" --type java
```

## Patterns

```bash
# Find annotations
rg -n "^@\w+" --type java

# Find Spring annotations
rg -n "@(Service|Repository|Controller|Component|Bean)" --type java

# Find REST endpoints
rg -n "@(GetMapping|PostMapping|PutMapping|DeleteMapping|RequestMapping)" --type java

# Find dependency injection
rg -n "@(Autowired|Inject)" --type java

# Find exception handling
rg -n "catch \(\w+ \w+\)" --type java

# Find streams
rg -n "\.stream\(\)|\.filter\(|\.map\(|\.collect\(" --type java

# Find Optional usage
rg -n "Optional\.|\.orElse|\.ifPresent" --type java
```

## Entry Points

```bash
# Find main methods
rg -n "public static void main\(String" --type java

# Find Spring Boot application
rg -n "@SpringBootApplication" --type java

# Find REST controllers
rg -n "@RestController|@Controller" --type java

# Find scheduled tasks
rg -n "@Scheduled" --type java

# Find message listeners
rg -n "@KafkaListener|@JmsListener" --type java
```

## Testing

```bash
# Find test classes
rg -n "^public class \w+Test" --type java

# Find test methods
rg -n "@Test" --type java -A 1

# Find test files
fd "Test.java$"
fd "IT.java$"  # Integration tests

# Find mocks
rg -n "@Mock|@MockBean|Mockito\." --type java

# Find assertions
rg -n "assert(Equals|True|False|NotNull|Throws)" --type java
```

## Dependencies

```bash
# View pom.xml dependencies
rg "<dependency>" pom.xml -A 5

# View build.gradle dependencies
rg "implementation|testImplementation" build.gradle

# Find all pom.xml files
fd "pom.xml"

# Find all build.gradle files
fd "build.gradle"
```
