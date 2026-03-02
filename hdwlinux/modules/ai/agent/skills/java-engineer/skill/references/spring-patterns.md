# Spring Patterns

## Constructor Injection

```java
@Service
public class UserService {
    private final UserRepository userRepository;
    private final EmailService emailService;
    
    // Constructor injection (preferred)
    public UserService(UserRepository userRepository, EmailService emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}
```

## Configuration Properties

```java
@ConfigurationProperties(prefix = "app.email")
public record EmailConfig(
    String host,
    int port,
    String username,
    @DefaultValue("false") boolean ssl
) {}

// application.yml
// app:
//   email:
//     host: smtp.example.com
//     port: 587
```

## Exception Handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("NOT_FOUND", ex.getMessage()));
    }
    
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ValidationException ex) {
        return ResponseEntity.badRequest()
            .body(new ErrorResponse("VALIDATION_ERROR", ex.getMessage()));
    }
}
```

## Validation

```java
public record CreateUserRequest(
    @NotBlank String name,
    @Email String email,
    @Min(18) int age
) {}

@PostMapping("/users")
public User createUser(@Valid @RequestBody CreateUserRequest request) {
    return userService.create(request);
}
```

## Async Processing

```java
@Async
public CompletableFuture<Report> generateReport(Long userId) {
    // Long-running operation
    return CompletableFuture.completedFuture(report);
}
```

## Caching

```java
@Cacheable(value = "users", key = "#id")
public User getUser(Long id) {
    return userRepository.findById(id).orElseThrow();
}

@CacheEvict(value = "users", key = "#user.id")
public User updateUser(User user) {
    return userRepository.save(user);
}
```
