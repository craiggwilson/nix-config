# Go Project Structure

## Standard Layout

```
myproject/
├── cmd/
│   ├── api/
│   │   └── main.go           # API server entry point
│   └── worker/
│       └── main.go           # Background worker entry point
├── internal/
│   ├── domain/               # Business logic, entities
│   │   ├── user.go
│   │   └── order.go
│   ├── service/              # Application services
│   │   ├── user_service.go
│   │   └── order_service.go
│   ├── repository/           # Data access
│   │   ├── user_repo.go
│   │   └── postgres/
│   │       └── user_repo.go
│   ├── handler/              # HTTP/gRPC handlers
│   │   └── user_handler.go
│   └── config/               # Configuration
│       └── config.go
├── pkg/                      # Public libraries (use sparingly)
│   └── validator/
│       └── validator.go
├── api/                      # API definitions
│   ├── openapi.yaml
│   └── proto/
│       └── user.proto
├── migrations/               # Database migrations
│   ├── 001_create_users.up.sql
│   └── 001_create_users.down.sql
├── scripts/                  # Build/deploy scripts
├── testdata/                 # Test fixtures
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

## Package Naming

```go
// Good: Short, lowercase, no underscores
package user
package httputil
package testhelper

// Bad
package userService      // no camelCase
package user_service     // no underscores
package UserService      // no capitals
```

## Internal Packages

```go
// internal/ packages can only be imported by packages
// in the same module tree

// myproject/internal/secret can be imported by:
// - myproject/cmd/api
// - myproject/internal/other

// Cannot be imported by:
// - otherproject/...
```

## Dependency Injection

```go
// cmd/api/main.go
func main() {
    cfg := config.Load()
    
    // Initialize dependencies
    db := postgres.Connect(cfg.DatabaseURL)
    
    // Wire up layers
    userRepo := postgres.NewUserRepository(db)
    userService := service.NewUserService(userRepo)
    userHandler := handler.NewUserHandler(userService)
    
    // Start server
    router := http.NewServeMux()
    router.Handle("/users", userHandler)
    http.ListenAndServe(cfg.Addr, router)
}
```

## Configuration Pattern

```go
// internal/config/config.go
type Config struct {
    Addr        string        `env:"ADDR" envDefault:":8080"`
    DatabaseURL string        `env:"DATABASE_URL,required"`
    LogLevel    string        `env:"LOG_LEVEL" envDefault:"info"`
    Timeout     time.Duration `env:"TIMEOUT" envDefault:"30s"`
}

func Load() (*Config, error) {
    var cfg Config
    if err := env.Parse(&cfg); err != nil {
        return nil, fmt.Errorf("parsing config: %w", err)
    }
    return &cfg, nil
}
```

## Error Handling Package

```go
// internal/errors/errors.go
package errors

import "errors"

// Sentinel errors
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrValidation   = errors.New("validation error")
)

// Domain error with context
type Error struct {
    Op   string // operation
    Kind error  // category
    Err  error  // underlying error
}

func (e *Error) Error() string {
    return fmt.Sprintf("%s: %v", e.Op, e.Err)
}

func (e *Error) Unwrap() error {
    return e.Err
}

func E(op string, kind error, err error) error {
    return &Error{Op: op, Kind: kind, Err: err}
}
```

## Makefile

```makefile
.PHONY: build test lint run

build:
	go build -o bin/api ./cmd/api

test:
	go test -race -cover ./...

lint:
	golangci-lint run

run:
	go run ./cmd/api

migrate-up:
	migrate -path migrations -database $(DATABASE_URL) up

migrate-down:
	migrate -path migrations -database $(DATABASE_URL) down 1

generate:
	go generate ./...

.DEFAULT_GOAL := build
```

## Module Initialization

```bash
# Initialize new module
go mod init github.com/myorg/myproject

# Add dependency
go get github.com/lib/pq

# Tidy dependencies
go mod tidy

# Vendor dependencies (optional)
go mod vendor
```

## Build Tags

```go
//go:build integration

package mypackage

// This file only included when: go test -tags=integration
```

```go
//go:build !production

package mypackage

// This file excluded when: go build -tags=production
```
