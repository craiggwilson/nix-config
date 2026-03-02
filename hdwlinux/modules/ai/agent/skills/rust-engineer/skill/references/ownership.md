# Rust Ownership

## Ownership Rules

1. Each value has exactly one owner
2. When the owner goes out of scope, the value is dropped
3. Ownership can be transferred (moved) or borrowed

## Move Semantics

```rust
let s1 = String::from("hello");
let s2 = s1;  // s1 is moved to s2
// println!("{}", s1);  // Error: s1 is no longer valid

// Clone for explicit copy
let s1 = String::from("hello");
let s2 = s1.clone();
println!("{} {}", s1, s2);  // Both valid
```

## Borrowing

```rust
// Immutable borrow
fn print_length(s: &String) {
    println!("Length: {}", s.len());
}

let s = String::from("hello");
print_length(&s);  // Borrow s
println!("{}", s);  // s still valid

// Mutable borrow
fn append_world(s: &mut String) {
    s.push_str(" world");
}

let mut s = String::from("hello");
append_world(&mut s);
```

## Borrowing Rules

1. Any number of immutable borrows OR exactly one mutable borrow
2. References must always be valid (no dangling references)

```rust
let mut s = String::from("hello");

let r1 = &s;     // OK
let r2 = &s;     // OK
// let r3 = &mut s;  // Error: can't borrow mutably while immutably borrowed

println!("{} {}", r1, r2);
// r1 and r2 no longer used after this point

let r3 = &mut s;  // OK now
```

## Lifetimes

```rust
// Explicit lifetime annotation
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Struct with references
struct Excerpt<'a> {
    part: &'a str,
}

impl<'a> Excerpt<'a> {
    fn level(&self) -> i32 {
        3
    }

    fn announce(&self, announcement: &str) -> &str {
        println!("Attention: {}", announcement);
        self.part
    }
}
```

## Lifetime Elision

```rust
// These are equivalent:
fn first_word(s: &str) -> &str { ... }
fn first_word<'a>(s: &'a str) -> &'a str { ... }

// Elision rules:
// 1. Each input reference gets its own lifetime
// 2. If one input lifetime, output gets that lifetime
// 3. If &self or &mut self, output gets self's lifetime
```

## Smart Pointers

```rust
// Box - heap allocation
let b = Box::new(5);

// Rc - reference counting (single-threaded)
use std::rc::Rc;
let a = Rc::new(5);
let b = Rc::clone(&a);

// Arc - atomic reference counting (thread-safe)
use std::sync::Arc;
let a = Arc::new(5);
let b = Arc::clone(&a);

// RefCell - interior mutability
use std::cell::RefCell;
let data = RefCell::new(5);
*data.borrow_mut() += 1;
```

## Common Patterns

```rust
// Take ownership and return it
fn process(s: String) -> String {
    // do something
    s
}

// Borrow when you don't need ownership
fn analyze(s: &str) -> usize {
    s.len()
}

// Use Cow for flexibility
use std::borrow::Cow;
fn process<'a>(s: &'a str) -> Cow<'a, str> {
    if s.contains("bad") {
        Cow::Owned(s.replace("bad", "good"))
    } else {
        Cow::Borrowed(s)
    }
}
```
