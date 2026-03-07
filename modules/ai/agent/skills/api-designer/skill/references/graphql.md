# GraphQL Schema Design

## Type Definitions

```graphql
type User {
  id: ID!
  name: String!
  email: String!
  posts: [Post!]!
  createdAt: DateTime!
}

type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
  comments: [Comment!]!
}

input CreateUserInput {
  name: String!
  email: String!
}
```

## Queries

```graphql
type Query {
  user(id: ID!): User
  users(first: Int, after: String): UserConnection!
  searchUsers(query: String!): [User!]!
}
```

## Mutations

```graphql
type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!
  deleteUser(id: ID!): DeleteUserPayload!
}

type CreateUserPayload {
  user: User
  errors: [Error!]!
}
```

## Pagination (Relay-style)

```graphql
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

## Error Handling

```graphql
type Error {
  field: String
  message: String!
  code: ErrorCode!
}

enum ErrorCode {
  NOT_FOUND
  VALIDATION_ERROR
  UNAUTHORIZED
  FORBIDDEN
}
```

## Best Practices

- Use `ID!` for identifiers
- Use `!` for non-nullable fields
- Use input types for mutations
- Return payload types with errors
- Implement Relay-style pagination
- Use enums for fixed values
