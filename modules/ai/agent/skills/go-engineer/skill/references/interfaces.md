# Go Interface Patterns

## Small, Focused Interfaces

```go
// Good: Single-method interfaces
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// Compose larger interfaces from smaller ones
type ReadWriter interface {
    Reader
    Writer
}
```

## Accept Interfaces, Return Structs

```go
// Good: Accept interface
func Process(r io.Reader) error {
    data, err := io.ReadAll(r)
    // ...
}

// Good: Return concrete type
func NewClient(cfg Config) *Client {
    return &Client{cfg: cfg}
}
```

## Interface Segregation

```go
// Bad: Large interface forces unnecessary implementation
type Repository interface {
    Create(ctx context.Context, entity Entity) error
    Read(ctx context.Context, id string) (Entity, error)
    Update(ctx context.Context, entity Entity) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, filter Filter) ([]Entity, error)
    Count(ctx context.Context, filter Filter) (int, error)
}

// Good: Segregated interfaces
type EntityReader interface {
    Read(ctx context.Context, id string) (Entity, error)
}

type EntityWriter interface {
    Create(ctx context.Context, entity Entity) error
    Update(ctx context.Context, entity Entity) error
}

type EntityDeleter interface {
    Delete(ctx context.Context, id string) error
}
```

## Implicit Interface Satisfaction

```go
// No explicit declaration needed
type MyReader struct {
    data []byte
    pos  int
}

func (r *MyReader) Read(p []byte) (n int, err error) {
    if r.pos >= len(r.data) {
        return 0, io.EOF
    }
    n = copy(p, r.data[r.pos:])
    r.pos += n
    return n, nil
}

// MyReader automatically satisfies io.Reader
var _ io.Reader = (*MyReader)(nil) // Compile-time check
```

## Interface for Testing (Dependency Injection)

```go
// Define interface where it's used, not where it's implemented
type UserStore interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

type UserService struct {
    store UserStore
}

func NewUserService(store UserStore) *UserService {
    return &UserService{store: store}
}

// In tests, provide mock implementation
type mockUserStore struct {
    users map[string]*User
}

func (m *mockUserStore) GetUser(ctx context.Context, id string) (*User, error) {
    if u, ok := m.users[id]; ok {
        return u, nil
    }
    return nil, ErrNotFound
}
```

## Functional Options Pattern

```go
type Server struct {
    addr    string
    timeout time.Duration
    logger  Logger
}

type Option func(*Server)

func WithTimeout(d time.Duration) Option {
    return func(s *Server) {
        s.timeout = d
    }
}

func WithLogger(l Logger) Option {
    return func(s *Server) {
        s.logger = l
    }
}

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{
        addr:    addr,
        timeout: 30 * time.Second, // default
        logger:  defaultLogger,    // default
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
server := NewServer(":8080",
    WithTimeout(60*time.Second),
    WithLogger(customLogger),
)
```

## Type Assertions and Type Switches

```go
// Type assertion
if rw, ok := w.(io.ReadWriter); ok {
    // w also implements Reader
}

// Type switch
func describe(i interface{}) string {
    switch v := i.(type) {
    case nil:
        return "nil"
    case int:
        return fmt.Sprintf("int: %d", v)
    case string:
        return fmt.Sprintf("string: %q", v)
    case error:
        return fmt.Sprintf("error: %v", v)
    default:
        return fmt.Sprintf("unknown: %T", v)
    }
}
```

## Empty Interface Best Practices

```go
// Avoid any/interface{} when possible
// Use generics instead in Go 1.18+

// Bad
func Process(data interface{}) interface{} {
    // requires type assertions
}

// Good
func Process[T any](data T) T {
    // type-safe
}
```
