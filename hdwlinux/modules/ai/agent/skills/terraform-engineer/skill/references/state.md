# Terraform State

## Remote Backends

### S3 Backend
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### GCS Backend
```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod"
  }
}
```

## State Locking

```hcl
# DynamoDB table for S3 locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

## State Commands

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Move resource
terraform state mv aws_instance.old aws_instance.new

# Remove from state (doesn't destroy)
terraform state rm aws_instance.web

# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0

# Pull remote state
terraform state pull > state.json

# Push state (dangerous!)
terraform state push state.json
```

## Workspaces

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new staging

# Select workspace
terraform workspace select production

# Use in configuration
resource "aws_instance" "web" {
  tags = {
    Environment = terraform.workspace
  }
}
```

## State Best Practices

- Always use remote state
- Enable state locking
- Enable encryption
- Use separate state per environment
- Never edit state manually
- Use `terraform state mv` for refactoring
- Backup state before major changes
