# Go Generics (Go 1.18+)

## Basic Generic Functions

```go
func Min[T constraints.Ordered](a, b T) T {
    if a < b {
        return a
    }
    return b
}

func Map[T, U any](slice []T, f func(T) U) []U {
    result := make([]U, len(slice))
    for i, v := range slice {
        result[i] = f(v)
    }
    return result
}

func Filter[T any](slice []T, predicate func(T) bool) []T {
    result := make([]T, 0)
    for _, v := range slice {
        if predicate(v) {
            result = append(result, v)
        }
    }
    return result
}

func Reduce[T, U any](slice []T, initial U, f func(U, T) U) U {
    result := initial
    for _, v := range slice {
        result = f(result, v)
    }
    return result
}
```

## Type Constraints

```go
import "golang.org/x/exp/constraints"

// Built-in constraints
// any          - no constraint
// comparable   - supports == and !=

// From constraints package
// Ordered      - supports < <= >= >
// Integer      - all integer types
// Float        - float32, float64
// Complex      - complex64, complex128
// Signed       - signed integers
// Unsigned     - unsigned integers

// Custom constraint
type Number interface {
    constraints.Integer | constraints.Float
}

func Sum[T Number](values []T) T {
    var sum T
    for _, v := range values {
        sum += v
    }
    return sum
}
```

## Generic Types

```go
// Generic struct
type Stack[T any] struct {
    items []T
}

func (s *Stack[T]) Push(item T) {
    s.items = append(s.items, item)
}

func (s *Stack[T]) Pop() (T, bool) {
    if len(s.items) == 0 {
        var zero T
        return zero, false
    }
    item := s.items[len(s.items)-1]
    s.items = s.items[:len(s.items)-1]
    return item, true
}

// Generic map wrapper
type Set[T comparable] map[T]struct{}

func NewSet[T comparable](items ...T) Set[T] {
    s := make(Set[T])
    for _, item := range items {
        s[item] = struct{}{}
    }
    return s
}

func (s Set[T]) Add(item T) {
    s[item] = struct{}{}
}

func (s Set[T]) Contains(item T) bool {
    _, ok := s[item]
    return ok
}
```

## Type Inference

```go
// Type can often be inferred
numbers := []int{1, 2, 3, 4, 5}
doubled := Map(numbers, func(n int) int { return n * 2 })

// Sometimes explicit type needed
result := Min[float64](3.14, 2.71)
```

## Generic Interfaces

```go
type Container[T any] interface {
    Add(T)
    Remove() T
    Size() int
}

type Queue[T any] struct {
    items []T
}

func (q *Queue[T]) Add(item T) {
    q.items = append(q.items, item)
}

func (q *Queue[T]) Remove() T {
    item := q.items[0]
    q.items = q.items[1:]
    return item
}

func (q *Queue[T]) Size() int {
    return len(q.items)
}

// Queue[T] satisfies Container[T]
var _ Container[int] = (*Queue[int])(nil)
```

## Pointer Method Constraint

```go
// When you need to call pointer methods on T
type Setter[T any] interface {
    Set(value T)
    *T // T must be a pointer type
}

// Alternative using ~
type Cloner[T any] interface {
    Clone() T
}

func CloneSlice[T Cloner[T]](items []T) []T {
    result := make([]T, len(items))
    for i, item := range items {
        result[i] = item.Clone()
    }
    return result
}
```

## Type Approximation (~)

```go
// ~ means "underlying type"
type MyInt int

type Integer interface {
    ~int | ~int8 | ~int16 | ~int32 | ~int64
}

func Double[T Integer](v T) T {
    return v * 2
}

var x MyInt = 5
y := Double(x) // Works because MyInt's underlying type is int
```

## Generic Result Type

```go
type Result[T any] struct {
    value T
    err   error
}

func Ok[T any](value T) Result[T] {
    return Result[T]{value: value}
}

func Err[T any](err error) Result[T] {
    return Result[T]{err: err}
}

func (r Result[T]) Unwrap() (T, error) {
    return r.value, r.err
}

func (r Result[T]) Map[U any](f func(T) U) Result[U] {
    if r.err != nil {
        return Err[U](r.err)
    }
    return Ok(f(r.value))
}
```
