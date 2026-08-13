# Database Connectivity Incident

## Summary

A controlled database-connectivity incident was performed against the CareFlow development platform to verify detection, investigation and recovery procedures.

The PostgreSQL security-group rule allowing ECS application tasks to reach Amazon RDS on TCP port 5432 was temporarily removed.

No application code, database credentials or database resources were modified.

## Normal Architecture

~~~text
Internet
   |
   v
CloudFront
   |
   v
Application Load Balancer
   |
   v
ECS Fargate
   |
   | TCP 5432
   v
Amazon RDS PostgreSQL
~~~

The RDS security group permits PostgreSQL traffic only from the ECS application security group.

## Healthy Baseline

Before fault injection:

- CloudFront HTTPS returned HTTP 200.
- `/health/ready` reported `healthy`.
- Database status reported `reachable`.
- ECS desired count was 1.
- ECS running count was 1.
- ECS pending count was 0.

## Fault Injection

The RDS ingress rule permitting PostgreSQL traffic from the ECS application security group was manually revoked.

The existing ECS task was then stopped so that ECS launched a replacement task requiring a new database connection.

This made the database-connectivity failure deterministic.

## Impact

The replacement application task could not establish a connection to PostgreSQL.

The public readiness endpoint returned:

~~~text
HTTP/2 503
~~~

This demonstrated that the readiness endpoint correctly detected the loss of a required application dependency.

## Detection

The incident was detected using:

- The public `/health/ready` endpoint.
- ECS service state and service events.
- CloudWatch application logs.
- The change from HTTP 200 to HTTP 503.

## Root Cause

The security-group ingress rule allowing PostgreSQL traffic from the ECS application security group to the RDS security group on TCP port 5432 had been removed.

The application code and RDS database itself remained deployed.

## Recovery

Terraform remained the source of truth and still declared the required database security-group rule.

A Terraform plan detected the manually introduced infrastructure drift.

Terraform then recreated the missing PostgreSQL ingress rule.

The restored network path was:

~~~text
ECS application security group
        |
        | TCP 5432
        v
RDS database security group
~~~

## Recovery Verification

After Terraform restored the rule:

- ECS returned to a healthy state.
- CloudFront returned HTTP 200.
- `/health/ready` reported `healthy`.
- Database status returned to `reachable`.
- The PostgreSQL ingress rule was confirmed present.

Recovered readiness response:

~~~json
{
  "status": "healthy",
  "check": "readiness",
  "database": "reachable"
}
~~~

## Lessons Learned

1. Dependency-aware readiness checks provide a clear signal when database connectivity fails.
2. Security groups provide a narrow network boundary between the application and database tiers.
3. Terraform can identify and repair manually introduced infrastructure drift.
4. Recovery should be verified through the public application path rather than assumed from infrastructure changes alone.
5. ECS service events and CloudWatch logs provide useful supporting evidence during investigation.

## Prevention

- Manage production security-group rules through Terraform.
- Review Terraform plans before infrastructure changes.
- Monitor application readiness failures.
- Alert on unhealthy ALB targets.
- Retain ECS application logs in CloudWatch.
- Maintain least-privilege network access between application and database tiers.

## Outcome

The controlled incident successfully demonstrated:

- Database-connectivity failure detection.
- HTTP 503 readiness behaviour during dependency failure.
- Investigation using AWS operational tooling.
- Infrastructure recovery using Terraform.
- End-to-end verification after recovery.
