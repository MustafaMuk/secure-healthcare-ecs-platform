# CareFlow Architecture

CareFlow is a containerised healthcare appointment API deployed to AWS using Terraform and GitHub Actions.

The platform uses synthetic healthcare data only.

## Runtime Architecture

The runtime diagram focuses on how public traffic reaches the application and how the application communicates with its supporting AWS services.

~~~mermaid
flowchart TB

    USER[Internet Client]

    subgraph EDGE["AWS Edge"]
        CF[Amazon CloudFront<br/>HTTPS Public Endpoint]
    end

    subgraph REGION["AWS eu-west-2"]

        subgraph VPC["CareFlow VPC"]

            subgraph PUBLIC["Public Subnets"]
                ALB[Application Load Balancer]
            end

            subgraph APPLICATION["Private Application Subnets"]
                ECS[Amazon ECS Fargate<br/>CareFlow API]
            end

            subgraph DATABASE["Isolated Database Subnets"]
                RDS[Amazon RDS<br/>PostgreSQL]
            end

            subgraph PRIVATE["Private AWS Service Access"]
                VPCE[VPC Endpoints]
            end

        end

        ECR[Amazon ECR]
        SECRETS[AWS Secrets Manager]
        CW[Amazon CloudWatch]
        SCALE[Application Auto Scaling]

    end

    USER -->|HTTPS| CF
    CF -->|Origin traffic| ALB
    ALB -->|TCP 3000| ECS
    ECS -->|TCP 5432| RDS

    ECS --> VPCE
    VPCE --> ECR
    VPCE --> SECRETS
    VPCE --> CW

    SCALE -->|Adjust task count| ECS
~~~

### Request path

A normal public request follows:

~~~text
Internet
   |
   | HTTPS
   v
Amazon CloudFront
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
Amazon RDS PostgreSQL
~~~

CloudFront is the public HTTPS entry point.

The Application Load Balancer accepts origin traffic from CloudFront and forwards application requests to ECS Fargate.

ECS tasks run in private application subnets.

Amazon RDS PostgreSQL runs in isolated database subnets and is not publicly accessible.

## CI/CD Architecture

The delivery diagram is kept separate from the runtime architecture so that the deployment path remains easy to follow.

~~~mermaid
flowchart TB

    DEV[Developer]
    REPO[GitHub Repository]

    subgraph CI["Continuous Integration"]
        TEST[Unit Tests and TypeScript Build]
        DBTEST[PostgreSQL Migration and Smoke Test]
        BUILD[Container Build]
        TRIVY[Trivy Vulnerability Scan]
        NONROOT[Non-root Runtime Verification]

        TEST --> DBTEST
        DBTEST --> BUILD
        BUILD --> TRIVY
        TRIVY --> NONROOT
    end

    subgraph CD["Continuous Deployment"]
        DEPLOY[Deployment Workflow]
    end

    OIDC[GitHub OIDC Provider]
    IAM[AWS IAM Deployment Role]
    ECR[Amazon ECR]
    ECS[Amazon ECS Fargate]
    HEALTH[CloudFront<br/>Public Health Check]

    DEV -->|Git push| REPO
    REPO --> TEST
    NONROOT -->|Successful main branch CI| DEPLOY

    DEPLOY -->|OIDC authentication| OIDC
    OIDC --> IAM

    DEPLOY -->|Build and push versioned image| ECR
    ECR -->|Container image| ECS

    DEPLOY -->|Render task definition and deploy| ECS
    DEPLOY -->|Verify after deployment| HEALTH
~~~

The deployment workflow authenticates to AWS through OpenID Connect.

Long-lived AWS access keys are not stored in GitHub for deployment.

The deployment role grants the workflow temporary AWS permissions required to publish container images and update the CareFlow ECS service.

The exact commit that successfully completed Continuous Integration is used for deployment.

## Infrastructure as Code

Terraform provisions and manages the AWS infrastructure.

~~~text
Terraform
   |
   +-- Networking
   +-- Security groups
   +-- VPC endpoints
   +-- Amazon ECR
   +-- Amazon RDS
   +-- ECS Fargate
   +-- Application Load Balancer
   +-- Amazon CloudFront
   +-- IAM
   +-- GitHub OIDC
   +-- CloudWatch
   +-- Application Auto Scaling
~~~

Terraform remote state is stored separately from the application infrastructure.

## Network Segmentation

The VPC is divided into separate infrastructure tiers.

### Public tier

The public tier contains the Application Load Balancer.

CloudFront provides the public HTTPS endpoint.

Direct ALB ingress is restricted so that the load balancer accepts origin traffic from CloudFront rather than arbitrary public clients.

### Application tier

The CareFlow API runs on ECS Fargate in private application subnets.

Inbound application traffic is permitted from the ALB on TCP port 3000.

The ECS tasks do not require direct inbound access from the internet.

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

ECS workloads use VPC endpoints to communicate privately with required AWS services.

These include:

- Amazon ECR API.
- Amazon ECR Docker registry.
- CloudWatch Logs.
- AWS Secrets Manager.
- Amazon S3.

This reduces the application's dependence on public internet connectivity for AWS service access.

## Secrets Management

Database credentials are stored in AWS Secrets Manager.

The ECS task execution process retrieves the required secret when the application task starts.

Credentials are not stored directly in:

- Application source code.
- Container images.
- GitHub workflow files.
- Terraform source files.

## Container Security

The production container is built and validated during Continuous Integration.

Security controls include:

- Multi-stage Docker builds.
- Non-root container execution.
- Trivy vulnerability scanning.
- Immutable ECR image tags.
- CI failure when critical vulnerabilities are detected.

During development, Trivy detected a critical vulnerability in unnecessary npm tooling contained in the original runtime image.

Rather than suppressing the finding, the production image was hardened by removing npm from the final runtime container.

The resulting container retains only the components required to execute the compiled CareFlow application.

## CI Pipeline

Continuous Integration runs when changes are pushed to `main` and when pull requests are opened.

The pipeline performs:

1. Source checkout.
2. Node.js configuration.
3. Dependency installation.
4. Unit testing.
5. TypeScript compilation.
6. PostgreSQL migrations.
7. End-to-end smoke testing.
8. Container image build.
9. Trivy vulnerability scanning.
10. Non-root runtime verification.

A failed CI run prevents automatic deployment.

## Deployment Pipeline

A successful Continuous Integration run on `main` triggers Continuous Deployment.

The deployment workflow performs:

1. Checkout of the tested commit.
2. AWS authentication through GitHub OIDC.
3. Amazon ECR authentication.
4. Container image build.
5. Push of a versioned image to ECR.
6. ECS task-definition rendering.
7. ECS service deployment.
8. Service-stability verification.
9. Public CloudFront readiness verification.

This creates the delivery path:

~~~text
Git push
   |
   v
Continuous Integration
   |
   v
Security validation
   |
   v
Continuous Deployment
   |
   v
GitHub OIDC
   |
   v
Amazon ECR
   |
   v
ECS Fargate
   |
   v
Public health verification
~~~

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
- An operational CloudWatch dashboard.

## Scaling

The ECS service uses Application Auto Scaling.

Scaling policies monitor:

- CPU utilisation.
- Memory utilisation.

The ECS task count can adjust according to application demand within configured limits.

## Application Health

CareFlow exposes a dependency-aware readiness endpoint:

~~~text
/health/ready
~~~

The endpoint verifies application readiness and PostgreSQL connectivity.

A healthy response resembles:

~~~json
{
  "status": "healthy",
  "check": "readiness",
  "database": "reachable"
}
~~~

## Resilience

The ECS service uses deployment circuit-breaker protection with automatic rollback enabled.

This provides protection against releases that fail to reach a healthy ECS service state.

The application readiness endpoint also exposes dependency failures to external monitoring.

## Database Connectivity Incident

A controlled database-connectivity incident was performed against the development environment.

The PostgreSQL security-group rule allowing ECS-to-RDS connectivity on TCP port 5432 was temporarily removed.

A replacement ECS task was unable to establish database connectivity.

The public readiness endpoint changed from:

~~~text
HTTP 200
database: reachable
~~~

to:

~~~text
HTTP 503
database: unreachable
~~~

Terraform detected the manually introduced infrastructure drift and restored the missing security-group rule.

After recovery:

- ECS returned to a healthy state.
- PostgreSQL became reachable.
- The public readiness endpoint returned HTTP 200.
- The security-group rule was confirmed restored.

The complete incident record is available at:

`docs/incidents/database-connectivity-incident.md`

## Security Summary

The platform demonstrates:

- Infrastructure as Code with Terraform.
- GitHub Actions CI/CD.
- GitHub OIDC authentication to AWS.
- Temporary deployment credentials.
- IAM role separation.
- AWS Secrets Manager.
- Network segmentation.
- Private ECS workloads.
- Isolated PostgreSQL infrastructure.
- Restricted security-group relationships.
- CloudFront-restricted ALB ingress.
- VPC endpoints.
- Non-root containers.
- Container vulnerability scanning.
- Immutable container images.
- CloudWatch monitoring.
- Dependency-aware health checks.
- Infrastructure drift recovery.

## Design Summary

CareFlow separates the platform into three concerns:

~~~text
Runtime
CloudFront -> ALB -> ECS -> RDS

Delivery
GitHub -> CI -> Trivy -> OIDC -> ECR -> ECS

Infrastructure
Terraform -> AWS
~~~

Keeping these concerns separate makes the architecture easier to understand, operate and explain.

The result is a small production-style AWS platform demonstrating infrastructure automation, secure container delivery, network segmentation, monitoring and incident recovery.
