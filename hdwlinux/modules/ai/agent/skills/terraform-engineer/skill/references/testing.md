# Terraform Testing

## Validation

```hcl
variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  type = string
  
  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Instance type must be t2 or t3 family."
  }
}
```

## terraform validate

```bash
# Validate configuration
terraform validate

# Format check
terraform fmt -check -recursive
```

## Terratest

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVpc(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "cidr_block": "10.0.0.0/16",
            "name":       "test-vpc",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

## terraform plan

```bash
# Generate plan
terraform plan -out=tfplan

# Show plan
terraform show tfplan

# Plan for specific target
terraform plan -target=aws_instance.web
```

## Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.77.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
```

## Policy as Code (OPA)

```rego
# policy/terraform.rego
package terraform

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.tags.Environment
    msg := "All instances must have Environment tag"
}
```

```bash
# Run policy check
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
opa eval --data policy/ --input tfplan.json "data.terraform.deny"
```
