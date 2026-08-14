# CareFlow Architecture

CareFlow is a containerised healthcare appointment API deployed to AWS using Terraform and GitHub Actions.

The platform uses synthetic healthcare data only.

## Platform Architecture

~~~mermaid
flowchart TB

    USER[Internet Client]
    TF[Terraform]

    subgraph GITHUB["GitHub"]
        REPO[Source Repository]
        CI[Continuous Integration]
        SCAN[Trivy Container Scan]
        CD[Continuous Deployment]

        REPO --> CI
        CI --> SCAN
        SCAN -->|Successful main branch build| CD
    end

    subgraph AWS["AWS - eu-west-2"]

        OIDC[GitHub OIDC Provider]
        IAM[IAM Deployment Role]
        ECR[Amazon ECR]

        CF[Amazon CloudFront<br/>HTTPS Public Endpoint]

        subgraph VPC["CareFlow VPC"]

            subgraph PUBLIC["Public Subnets"]
                ALB[Application Load Balancer]
            end

            subgraph APP["Private Application Subnets"]
                ECS[Amazon ECS Fargate<br/>CareFlow API]
            end

            subgraph DATABASE["Isolated Database Subnets"]
                RDS[Amazon RDS<br/>PostgreSQL]
            end

            subgraph PRIVATE_ACCESS["Private AWS Service Access"]
                VPCE[VPC Endpoints]
            end
        end

        SECRETS[AWS Secrets Manager]
        CW[Amazon CloudWatch]
        SCALE[Application Auto Scaling]
    end

    USER -->|HTTPS| CF
    CF -->|Origin traffic| ALB
    ALB -->|TCP 3000| ECS
    ECS -->|TCP 5432| RDS

    ECS -->|Database credentials| SECRETS
    ECS -->|Private AWS API access| VPCE
    ECS -->|Logs and metrics| CW
    SCALE -->|Scale service| ECS

    CD -->|OIDC token| OIDC
    OIDC --> IAM
    IAM -->|Temporary AWS credentials| CD

    CD -->|Build and push image| ECR
    ECR -->|Versioned image| ECS

    TF -.->|Provision and manage| AWS
~~~

## Runtime Request Path

A normal request follows this path:

~~~text
Internet
   |
   | HTTPS
   v
CloudFront
   |
   v
Application Load Balancer
   |
   | TCP 3000
   v
ECS Fargate
   |
   | TCP 5432
   v
RDS PostgreSQL
~~~

CloudFront is the public HTTPS entry point.

The Application Load Balancer accepts application traffic from CloudFront and forwards it to ECS Fargate.

ECS tasks run in private application subnets.

Amazon RDS PostgreSQL runs in isolated database subnets and is not publicly accessible.

## CI/CD Path

Application delivery follows this path:

~~~text
Developer pushes to main
        |
        v
GitHub Actions
Continuous Integration
        |
        +-- Install dependencies
        +-- Run unit tests
        +-- Compile TypeScript
        +-- Apply PostgreSQL migrations
        +-- Run smoke test
        +-- Build container image
        +-- Run Trivy vulnerability scan
        +-- Verify non-root runtime
        |
        v
Successful CI
        |
        v
Continuous Deployment
        |
        +-- GitHub OIDC authentication
        +-- Temporary AWS credentials
        +-- Build versioned image
        +-- Push image to Amazon ECR
        +-- Render ECS task definition
        +-- Deploy to ECS Fargate
        +-- Wait for service stability
        +-- Verify public health endpoint
~~~

GitHub Actions authenticates to AWS through OpenID Connect.

Long-lived AWS access keys are not stored in GitHub for deployment.

The deployment workflow uses the exact commit that successfully completed Continuous Integration.

## Network Segmentation

### Public tier

The public-facing path consists of:

- Amazon CloudFront.
- Application Load Balancer.

Direct ALB ingress is restricted to CloudFront origin traffic.

### Application tier

The CareFlow API runs on ECS Fargate in private application subnets.

Inbound application traffic is accepted from the ALB on TCP port 3000.

### Database tier

Amazon RDS PostgreSQL runs in isolated database subnets.

Database access is restricted to:

~~~text
Source: ECS application security group
Protocol: TCP
Port: 5432
~~~

The database does not accept public internet traffic.

## Private AWS Service Access

ECS workloads use VPC endpoints for private access to required AWS services, including:

- Amazon ECR.
- CloudWatch Logs.
- AWS Secrets Manager.
- Amazon S3.

This reduces dependence on public internet access from the application tier.

## Security Controls

The platform includes:

- GitHub Actions OIDC authentication.
- Temporary AWS deployment credentials.
- IAM role separation.
- AWS Secrets Manager for database credentials.
- Private ECS application subnets.
- Isolated RDS database subnets.
- Security-group-to-security-group rules.
- CloudFront-restricted ALB ingress.
- Non-root container execution.
- Trivy vulnerability scanning in CI.
- Immutable ECR image tags.
- Dependency-aware readiness checks.
- Terraform-managed infrastructure.

## Container Security

Continuous Integration builds the production container and scans it with Trivy before deployment is permitted.

During development, Trivy detected a critical vulnerability in software included in the original Node.js runtime image.

The runtime image was hardened by removing unnecessary npm tooling from the final container and retaining only the components required to execute the application.

The resulting production container runs as the non-root `node` user.

## Secrets Management

Database credentials are stored in AWS Secrets Manager.

The ECS execution role retrieves the required secret at task startup.

Credentials are not stored directly in:

- Application source code.
- Docker images.
- GitHub workflow files.
- Terraform source files.

## Observability

CareFlow uses Amazon CloudWatch for operational visibility.

Monitoring includes:

- ECS application logs.
- PostgreSQL logs.
- ECS CPU alarms.
- ECS memory alarms.
- ALB unhealthy-target alarms.
- HTTP 5xx alarms.
- RDS CPU alarms.
- RDS storage alarms.
- CloudWatch operational dashboard.

## Scaling

The ECS service uses Application Auto Scaling.

Scaling policies monitor:

- CPU utilisation.
- Memory utilisation.

This allows the number of ECS tasks to adjust according to application demand within configured limits.

## Resilience

The ECS service uses deployment circuit-breaker protection with automatic rollback enabled.

The application also exposes a dependency-aware readiness endpoint:

~~~text
/health/ready
~~~

The endpoint verifies application readiness and PostgreSQL connectivity.

## Incident Recovery Exercise

A controlled database-connectivity incident was performed against the development environment.

The PostgreSQL security-group rule allowing ECS-to-RDS connectivity on TCP port 5432 was temporarily removed.

A replacement ECS task was unable to establish database connectivity and the public readiness endpoint returned HTTP 503.

Terraform detected the manually introduced infrastructure drift and restored the missing rule.

After recovery:

- ECS returned to a healthy state.
- PostgreSQL became reachable.
- The public readiness endpoint returned HTTP 200.
- The security-group rule was confirmed restored.

Full incident documentation is available at:

`docs/incidents/database-connectivity-incident.md`

## Infrastructure as Code

Terraform provisions and manages the AWS infrastructure, including:

- VPC networking.
- Public, private and isolated subnets.
- Security groups.
- VPC endpoints.
- Amazon ECR.
- Amazon RDS PostgreSQL.
- AWS Secrets Manager integration.
- ECS Fargate.
- Application Load Balancer.
- Amazon CloudFront.
- IAM roles and policies.
- GitHub OIDC.
- CloudWatch monitoring.
- ECS autoscaling.

Terraform remote state is stored separately from the application infrastructure.

## Design Summary

CareFlow separates public ingress, application compute and database resources across distinct network tiers.

GitHub Actions provides automated testing, security scanning and deployment.

Terraform maintains AWS infrastructure as code, while CloudWatch provides operational visibility.

The result is a small but production-style platform designed to demonstrate secure deployment, infrastructure automation, container delivery and incident recovery.
