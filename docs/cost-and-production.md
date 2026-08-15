# Cost and Production Considerations

CareFlow is deployed as a development and portfolio environment rather than a full production healthcare system.

The current architecture intentionally balances realistic AWS design with controlled infrastructure cost.

## Current Development Footprint

The development environment uses:

- One ECS Fargate service.
- ECS tasks sized at 0.25 vCPU and 512 MiB memory.
- ECS Application Auto Scaling with a minimum of 1 task and maximum of 2 tasks.
- One `db.t4g.micro` Amazon RDS PostgreSQL instance.
- 20 GiB of encrypted gp3 database storage.
- One Application Load Balancer.
- One Amazon CloudFront distribution.
- Four interface VPC endpoints:
  - ECR API.
  - ECR Docker registry.
  - CloudWatch Logs.
  - Secrets Manager.
- One S3 gateway VPC endpoint.
- Amazon ECR container storage.
- CloudWatch logs, metrics, alarms and dashboard.
- 14-day application and database log retention.

## Main Cost Drivers

The largest expected cost contributors are:

### Amazon RDS

The PostgreSQL database runs continuously while the environment is active.

Database compute and storage therefore represent a persistent part of the development cost.

### Application Load Balancer

The ALB incurs a running cost even when application traffic is low.

Additional cost depends on the amount of traffic and load-balancer capacity consumed.

### VPC Interface Endpoints

Interface endpoints provide private communication between ECS and AWS services.

They improve network isolation but introduce an hourly cost for each deployed endpoint, plus data-processing charges.

The S3 gateway endpoint does not have the same hourly interface-endpoint charge.

### ECS Fargate

Fargate cost depends on the CPU and memory allocated to running tasks.

CareFlow keeps the development task size deliberately small and limits autoscaling to a maximum of two tasks.

### CloudFront and Data Transfer

CloudFront cost depends primarily on request volume and data transferred to users.

Traffic for this portfolio environment is expected to remain low.

### CloudWatch

CloudWatch costs depend on log ingestion, retained log volume, metrics and alarms.

CareFlow limits application and PostgreSQL log retention to 14 days in the development environment.

### Amazon ECR

Container registry cost depends mainly on stored image volume and data transfer.

CareFlow uses immutable versioned images and an ECR lifecycle policy to prevent unnecessary image accumulation.

## Development Cost Decisions

Several design decisions intentionally reduce cost:

- Small Fargate task sizing.
- Maximum ECS capacity of two tasks.
- `db.t4g.micro` PostgreSQL instance.
- 20 GiB database storage.
- Short CloudWatch log retention.
- Short development database backup retention.
- ECR image lifecycle management.
- No NAT Gateway.
- S3 gateway endpoint for private S3 access.
- Single development environment.

The project does retain interface VPC endpoints because demonstrating private AWS service connectivity is an intentional part of the architecture.

## Production Changes

A real production deployment would require changes beyond this development environment.

### Database Availability

The development database is intentionally cost-conscious.

For production I would consider:

- Multi-AZ RDS deployment.
- Longer automated backup retention.
- Deletion protection.
- Final snapshots during database replacement or deletion.
- Point-in-time recovery requirements.
- Tested database restore procedures.

### Application Availability

The development environment can operate with a single ECS task.

For production I would use:

- A minimum of at least two application tasks.
- Tasks distributed across multiple Availability Zones.
- Production-specific autoscaling limits.
- Load and capacity testing before choosing scaling thresholds.

### Edge Security

The current architecture uses CloudFront as the public HTTPS entry point.

A production system could additionally use:

- A custom domain.
- AWS Certificate Manager certificates.
- AWS WAF.
- Rate limiting.
- Additional CloudFront security policies.

These services were not added merely to increase the number of AWS products in the portfolio project.

### Monitoring

Production monitoring would require operational targets rather than demonstration alarms.

Examples include:

- Availability objectives.
- Latency thresholds.
- Error-rate alerts.
- Database connection monitoring.
- Alert routing and escalation.
- Longer-term metric retention.
- Tested operational runbooks.

### Security

Additional production controls could include:

- Automated secret rotation.
- More restrictive VPC endpoint policies.
- Periodic IAM access review.
- AWS Config or equivalent configuration monitoring.
- CloudTrail analysis.
- Centralised security monitoring.
- Dependency and container scanning policies with documented exception handling.

### Disaster Recovery

The portfolio environment demonstrates service recovery and Terraform-based drift correction but is not a disaster-recovery architecture.

A production design would define:

- Recovery Time Objective (RTO).
- Recovery Point Objective (RPO).
- Database restore procedures.
- Infrastructure recreation procedures.
- Backup validation.
- Regional recovery requirements where justified.

## Cost Optimisation Opportunities

If the objective were to minimise the cost of the development environment further, the first components I would review are:

1. Interface VPC endpoints.
2. Application Load Balancer runtime.
3. Continuously running RDS capacity.
4. Continuously running ECS capacity.
5. CloudWatch log volume.

Removing these components purely for cost would reduce how closely the project represents a production-style AWS architecture, so the current environment deliberately accepts some additional cost for architectural realism.

## Summary

CareFlow is intentionally sized as a small development platform while retaining production-style architecture patterns.

The project demonstrates not only how AWS resources are deployed, but also the trade-offs between:

- Cost.
- Availability.
- Security.
- Network isolation.
- Operational complexity.

The production considerations above are design improvements rather than claims about features currently implemented in the development environment.
