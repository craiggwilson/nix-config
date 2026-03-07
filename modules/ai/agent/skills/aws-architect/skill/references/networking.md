# AWS Networking

## VPC Design

```
VPC: 10.0.0.0/16
├── Public Subnets (internet-facing)
│   ├── 10.0.1.0/24 (AZ-a)
│   ├── 10.0.2.0/24 (AZ-b)
│   └── 10.0.3.0/24 (AZ-c)
├── Private Subnets (application)
│   ├── 10.0.11.0/24 (AZ-a)
│   ├── 10.0.12.0/24 (AZ-b)
│   └── 10.0.13.0/24 (AZ-c)
└── Database Subnets (isolated)
    ├── 10.0.21.0/24 (AZ-a)
    ├── 10.0.22.0/24 (AZ-b)
    └── 10.0.23.0/24 (AZ-c)
```

## Security Groups

```hcl
# Web tier
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# App tier - only from web tier
ingress {
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  security_groups = [aws_security_group.web.id]
}
```

## Load Balancers

| Type | Use Case |
|------|----------|
| ALB | HTTP/HTTPS, path-based routing |
| NLB | TCP/UDP, low latency |
| GLB | Third-party appliances |

## VPC Endpoints

- **Gateway Endpoints** - S3, DynamoDB (free)
- **Interface Endpoints** - Other services (cost per hour)

## Route53

- Use alias records for AWS resources
- Health checks for failover
- Latency-based routing for multi-region
- Private hosted zones for internal DNS

## CloudFront

- Cache static content at edge
- Use Origin Access Identity for S3
- Enable compression
- Use custom error pages
