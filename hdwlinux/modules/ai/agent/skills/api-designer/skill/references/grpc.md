# gRPC Service Design

## Proto File Structure

```protobuf
syntax = "proto3";

package myservice.v1;

option go_package = "github.com/myorg/myservice/gen/go/v1";

import "google/protobuf/timestamp.proto";

service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
}
```

## Message Definitions

```protobuf
message User {
  string id = 1;
  string name = 2;
  string email = 3;
  google.protobuf.Timestamp created_at = 4;
}

message GetUserRequest {
  string id = 1;
}

message GetUserResponse {
  User user = 1;
}

message ListUsersRequest {
  int32 page_size = 1;
  string page_token = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  string next_page_token = 2;
}
```

## Streaming

```protobuf
// Server streaming
rpc ListUsers(ListUsersRequest) returns (stream User);

// Client streaming
rpc UploadUsers(stream User) returns (UploadResponse);

// Bidirectional streaming
rpc Chat(stream Message) returns (stream Message);
```

## Error Handling

```protobuf
import "google/rpc/status.proto";

// Use standard gRPC status codes:
// OK, CANCELLED, UNKNOWN, INVALID_ARGUMENT,
// DEADLINE_EXCEEDED, NOT_FOUND, ALREADY_EXISTS,
// PERMISSION_DENIED, UNAUTHENTICATED, etc.
```

## Best Practices

- Use semantic versioning in package names
- Reserve field numbers for deleted fields
- Use `repeated` for lists
- Use `optional` for nullable fields (proto3)
- Use well-known types (Timestamp, Duration)
- Define clear service boundaries
