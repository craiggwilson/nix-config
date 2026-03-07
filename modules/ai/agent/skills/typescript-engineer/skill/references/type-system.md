# TypeScript Type System

## Basic Types

```typescript
// Primitives
const name: string = "Alice";
const age: number = 30;
const active: boolean = true;

// Arrays
const numbers: number[] = [1, 2, 3];
const names: Array<string> = ["Alice", "Bob"];

// Tuples
const pair: [string, number] = ["age", 30];

// Objects
const user: { name: string; age: number } = { name: "Alice", age: 30 };
```

## Interfaces vs Types

```typescript
// Interface - prefer for object shapes
interface User {
  id: string;
  name: string;
  email: string;
}

// Type - prefer for unions, primitives, tuples
type Status = "pending" | "active" | "inactive";
type ID = string | number;
type Pair = [string, number];

// Interface extension
interface Admin extends User {
  permissions: string[];
}

// Type intersection
type AdminUser = User & { permissions: string[] };
```

## Generics

```typescript
// Generic function
function first<T>(items: T[]): T | undefined {
  return items[0];
}

// Generic interface
interface Repository<T> {
  find(id: string): Promise<T | null>;
  save(item: T): Promise<T>;
  delete(id: string): Promise<void>;
}

// Generic constraints
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// Default type parameter
interface Response<T = unknown> {
  data: T;
  status: number;
}
```

## Discriminated Unions

```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

function handleResult<T>(result: Result<T>): T {
  if (result.success) {
    return result.data; // TypeScript knows data exists
  }
  throw result.error; // TypeScript knows error exists
}

// State machine
type State =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: User[] }
  | { status: "error"; error: Error };
```

## Utility Types

```typescript
// Partial - all properties optional
type PartialUser = Partial<User>;

// Required - all properties required
type RequiredUser = Required<User>;

// Pick - select properties
type UserName = Pick<User, "name" | "email">;

// Omit - exclude properties
type UserWithoutId = Omit<User, "id">;

// Record - key-value map
type UserMap = Record<string, User>;

// ReturnType - extract return type
type FetchResult = ReturnType<typeof fetchUser>;

// Parameters - extract parameter types
type FetchParams = Parameters<typeof fetchUser>;
```

## Conditional Types

```typescript
type IsString<T> = T extends string ? true : false;

type ExtractArray<T> = T extends (infer U)[] ? U : never;

type Awaited<T> = T extends Promise<infer U> ? U : T;

// Distributive conditional types
type NonNullable<T> = T extends null | undefined ? never : T;
```

## Template Literal Types

```typescript
type EventName = `on${Capitalize<string>}`;
type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";
type Endpoint = `/${string}`;
type Route = `${HttpMethod} ${Endpoint}`;

// Example: "GET /users", "POST /orders"
```

## Type Guards

```typescript
// typeof guard
function process(value: string | number) {
  if (typeof value === "string") {
    return value.toUpperCase();
  }
  return value * 2;
}

// instanceof guard
function handleError(error: unknown) {
  if (error instanceof Error) {
    console.log(error.message);
  }
}

// Custom type guard
function isUser(obj: unknown): obj is User {
  return (
    typeof obj === "object" &&
    obj !== null &&
    "id" in obj &&
    "name" in obj
  );
}
```

## Zod for Runtime Validation

```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
  age: z.number().int().positive().optional(),
});

type User = z.infer<typeof UserSchema>;

function parseUser(data: unknown): User {
  return UserSchema.parse(data);
}
```
