# Terraform Patterns

## for_each vs count

```hcl
# count - use for identical resources
resource "aws_instance" "web" {
  count = 3
  ami   = "ami-12345"
  tags  = { Name = "web-${count.index}" }
}

# for_each - use for distinct resources
resource "aws_iam_user" "users" {
  for_each = toset(["alice", "bob", "charlie"])
  name     = each.key
}

# for_each with map
resource "aws_instance" "servers" {
  for_each = {
    web = { type = "t3.small", az = "us-east-1a" }
    api = { type = "t3.medium", az = "us-east-1b" }
  }
  
  instance_type     = each.value.type
  availability_zone = each.value.az
  tags              = { Name = each.key }
}
```

## Dynamic Blocks

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

## Conditionals

```hcl
# Conditional resource
resource "aws_eip" "web" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.web.id
}

# Conditional value
locals {
  environment = var.is_production ? "prod" : "dev"
}

# Conditional in for_each
resource "aws_instance" "optional" {
  for_each = var.create_instances ? var.instances : {}
  # ...
}
```

## Data Sources

```hcl
# Look up existing resources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }
}

data "aws_vpc" "existing" {
  tags = { Name = "main" }
}

resource "aws_instance" "web" {
  ami       = data.aws_ami.ubuntu.id
  subnet_id = data.aws_vpc.existing.id
}
```

## Locals

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
  
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_instance" "web" {
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
  })
}
```

## Lifecycle Rules

```hcl
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [tags]
  }
}
```
