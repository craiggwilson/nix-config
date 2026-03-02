# Personal Coding Practices

These practices apply to all code, regardless of language.
Be idiomatic to the language while following these principles.

## Error Handling

- Fail early and add context to errors
- Prefer explicit error handling over silent failures
- Centralize error handling where possible

## Comments and Documentation

- Explain "why" or "how", never "what"
- All exported/public types and functions must have documentation
- Documentation explains purpose and usage, not implementation details

## Testing

- Arrange/Act/Assert pattern for test structure
- All public/exported functions should have test coverage
- TDD is preferred but not required

## Code Organization

- Single responsibility: one place for things to happen
- Single source of truth for configuration and state
- Centralized error handling
- Single entry points (barrel exports where idiomatic)
- A little copying is better than a little dependency

### Ordering Within Files

1. Imports (stdlib, external, internal types, internal implementations)
2. Constants and configuration
3. Type definitions (alphabetized)
4. Public/exported items (alphabetized)
5. Private/non-exported items (alphabetized)

### Field Ordering

Alphabetize fields within types, structs, and configuration objects.

## Naming

- Follow language idioms for naming conventions
- Avoid abbreviations unless commonly understood (e.g., `cfg`, `ctx`, `id`)

## Preferences

- Immutability over shared state
- Functional over imperative
- Dependency injection over global state (constructor injection preferred)

## Logging

- Minimal: only what helps debugging or is critical for users
- Never log in hot paths
- Always log at system boundaries
- Always include context (IDs, relevant state) when logging
