# Go Testing Patterns

## Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -1, -2, -3},
        {"zero", 0, 0, 0},
        {"mixed", -1, 5, 4},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d", 
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

## Subtests with Parallel Execution

```go
func TestParallel(t *testing.T) {
    tests := []struct {
        name  string
        input string
    }{
        {"test1", "input1"},
        {"test2", "input2"},
    }

    for _, tt := range tests {
        tt := tt // capture range variable
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            // test code
        })
    }
}
```

## Test Helpers

```go
func TestWithHelper(t *testing.T) {
    user := createTestUser(t)
    // use user...
}

func createTestUser(t *testing.T) *User {
    t.Helper() // marks this as a helper function
    
    user, err := NewUser("test@example.com")
    if err != nil {
        t.Fatalf("failed to create test user: %v", err)
    }
    return user
}
```

## Test Fixtures

```go
func TestMain(m *testing.M) {
    // Setup
    db := setupTestDB()
    
    // Run tests
    code := m.Run()
    
    // Teardown
    db.Close()
    
    os.Exit(code)
}

// Or use t.Cleanup
func TestWithCleanup(t *testing.T) {
    db := setupTestDB(t)
    t.Cleanup(func() {
        db.Close()
    })
    // test code
}
```

## Mocking with Interfaces

```go
type UserRepository interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

type mockUserRepo struct {
    users map[string]*User
    err   error
}

func (m *mockUserRepo) GetUser(ctx context.Context, id string) (*User, error) {
    if m.err != nil {
        return nil, m.err
    }
    return m.users[id], nil
}

func TestUserService(t *testing.T) {
    mock := &mockUserRepo{
        users: map[string]*User{
            "123": {ID: "123", Name: "Test"},
        },
    }
    
    svc := NewUserService(mock)
    user, err := svc.GetUser(context.Background(), "123")
    
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Name != "Test" {
        t.Errorf("got name %q; want %q", user.Name, "Test")
    }
}
```

## Benchmarks

```go
func BenchmarkProcess(b *testing.B) {
    data := generateTestData()
    b.ResetTimer() // exclude setup time
    
    for i := 0; i < b.N; i++ {
        Process(data)
    }
}

// With sub-benchmarks
func BenchmarkProcessSizes(b *testing.B) {
    sizes := []int{10, 100, 1000, 10000}
    
    for _, size := range sizes {
        b.Run(fmt.Sprintf("size-%d", size), func(b *testing.B) {
            data := generateData(size)
            b.ResetTimer()
            
            for i := 0; i < b.N; i++ {
                Process(data)
            }
        })
    }
}

// Report allocations
func BenchmarkWithAllocs(b *testing.B) {
    b.ReportAllocs()
    for i := 0; i < b.N; i++ {
        Process()
    }
}
```

## Fuzzing (Go 1.18+)

```go
func FuzzParseJSON(f *testing.F) {
    // Seed corpus
    f.Add([]byte(`{"name": "test"}`))
    f.Add([]byte(`{}`))
    f.Add([]byte(`{"count": 42}`))
    
    f.Fuzz(func(t *testing.T, data []byte) {
        var result map[string]interface{}
        err := json.Unmarshal(data, &result)
        if err != nil {
            return // invalid JSON is expected
        }
        
        // Re-marshal and check round-trip
        encoded, err := json.Marshal(result)
        if err != nil {
            t.Errorf("failed to re-marshal: %v", err)
        }
        
        var result2 map[string]interface{}
        if err := json.Unmarshal(encoded, &result2); err != nil {
            t.Errorf("failed to unmarshal re-encoded: %v", err)
        }
    })
}
```

## Testing HTTP Handlers

```go
func TestHandler(t *testing.T) {
    req := httptest.NewRequest("GET", "/users/123", nil)
    w := httptest.NewRecorder()
    
    handler := NewUserHandler(mockRepo)
    handler.ServeHTTP(w, req)
    
    resp := w.Result()
    if resp.StatusCode != http.StatusOK {
        t.Errorf("got status %d; want %d", resp.StatusCode, http.StatusOK)
    }
    
    body, _ := io.ReadAll(resp.Body)
    // assert on body...
}
```

## Golden Files

```go
func TestOutput(t *testing.T) {
    result := Generate()
    
    golden := filepath.Join("testdata", t.Name()+".golden")
    
    if *update {
        os.WriteFile(golden, []byte(result), 0644)
    }
    
    expected, err := os.ReadFile(golden)
    if err != nil {
        t.Fatalf("failed to read golden file: %v", err)
    }
    
    if result != string(expected) {
        t.Errorf("output mismatch; run with -update to update golden files")
    }
}
```

## Race Detection

```bash
# Run tests with race detector
go test -race ./...

# Run specific test
go test -race -run TestConcurrent ./...
```
