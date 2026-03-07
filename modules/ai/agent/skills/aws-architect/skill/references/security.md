# AWS Security

## IAM Best Practices

### Least Privilege Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalTag/team": "backend"
        }
      }
    }
  ]
}
```

### Role-Based Access
- Use roles, not long-term credentials
- Use instance profiles for EC2
- Use task roles for ECS
- Use IRSA for EKS

## KMS

### Key Types
- **AWS Managed** - Automatic rotation
- **Customer Managed** - Full control
- **Customer Owned** - On-premises HSM

### Best Practices
- Enable automatic key rotation
- Use key policies for access control
- Use grants for temporary access
- Audit with CloudTrail

## Secrets Manager

```python
import boto3

client = boto3.client('secretsmanager')
secret = client.get_secret_value(SecretId='my-secret')
credentials = json.loads(secret['SecretString'])
```

### Best Practices
- Enable automatic rotation
- Use resource policies
- Reference in CloudFormation
- Cache secrets in application

## Security Services

| Service | Purpose |
|---------|---------|
| GuardDuty | Threat detection |
| Security Hub | Security posture |
| Inspector | Vulnerability scanning |
| Macie | Data discovery |
| WAF | Web application firewall |

## Compliance

- Enable CloudTrail in all regions
- Enable Config rules
- Use AWS Organizations SCPs
- Enable VPC Flow Logs
