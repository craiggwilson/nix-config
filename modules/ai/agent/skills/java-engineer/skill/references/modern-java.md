# Modern Java (17+)

## Records

```java
// Immutable data carrier
public record User(Long id, String name, String email) {
    // Compact constructor for validation
    public User {
        Objects.requireNonNull(name, "name cannot be null");
        Objects.requireNonNull(email, "email cannot be null");
    }
    
    // Additional methods
    public String displayName() {
        return name + " <" + email + ">";
    }
}

// Usage
var user = new User(1L, "John", "john@example.com");
String name = user.name();  // accessor method
```

## Sealed Classes

```java
public sealed interface Shape permits Circle, Rectangle, Triangle {
    double area();
}

public record Circle(double radius) implements Shape {
    public double area() { return Math.PI * radius * radius; }
}

public record Rectangle(double width, double height) implements Shape {
    public double area() { return width * height; }
}

public final class Triangle implements Shape {
    // ...
}
```

## Pattern Matching

```java
// instanceof pattern matching
if (obj instanceof String s) {
    System.out.println(s.length());
}

// Switch pattern matching (Java 21)
String describe(Object obj) {
    return switch (obj) {
        case Integer i -> "Integer: " + i;
        case String s -> "String: " + s;
        case null -> "null";
        default -> "Unknown";
    };
}

// Record patterns (Java 21)
void process(Shape shape) {
    switch (shape) {
        case Circle(var r) -> System.out.println("Circle with radius " + r);
        case Rectangle(var w, var h) -> System.out.println("Rectangle " + w + "x" + h);
        default -> System.out.println("Other shape");
    }
}
```

## Text Blocks

```java
String json = """
    {
        "name": "John",
        "email": "john@example.com"
    }
    """;
```

## Virtual Threads (Java 21)

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    IntStream.range(0, 10_000).forEach(i -> {
        executor.submit(() -> {
            Thread.sleep(Duration.ofSeconds(1));
            return i;
        });
    });
}
```
