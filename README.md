# CareFlow — Secure Healthcare ECS Platform

[![Continuous Integration](https://github.com/MustafaMuk/secure-healthcare-ecs-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/MustafaMuk/secure-healthcare-ecs-platform/actions/workflows/ci.yml)
[![Continuous Deployment](https://github.com/MustafaMuk/secure-healthcare-ecs-platform/actions/workflows/deploy.yml/badge.svg)](https://github.com/MustafaMuk/secure-healthcare-ecs-platform/actions/workflows/deploy.yml)

CareFlow is a containerised TypeScript and PostgreSQL application deployed to AWS ECS Fargate using Terraform and GitHub Actions.

The project focuses less on the appointment API itself and more on the platform around it: infrastructure as code, network isolation, workload identity, container security, automated deployment, monitoring and recovery.

> **Synthetic data only**
>
> CareFlow is a portfolio and development environment. It contains no real patient, clinical or personally identifiable information and is not presented as a production healthcare system.

---

## Why I built this

I wanted a project that went beyond:

~~~text
Dockerfile
+
EC2 instance
+
README saying "deployed to AWS"
~~~

The goal was to build something I could trace end to end:

~~~text
Git push
   |
   v
GitHub Actions
   |
   v
Security validation
   |
   v
AWS deployment
   |
   v
CloudFront
   |
   v
ECS
   |
   v
PostgreSQL
~~~

and then deliberately break part of it, investigate what happened and recover it.

---

## What the platform includes

- TypeScript application with PostgreSQL persistence.
- Synthetic appointment and audit data.
- Multi-stage Docker builds.
- Non-root production containers.
- Amazon ECS Fargate.
- Amazon RDS PostgreSQL.
- Amazon ECR.
- Amazon CloudFront.
- Application Load Balancer.
- Public, private application and isolated database subnets.
- AWS Secrets Manager.
- Private VPC endpoints.
- Terraform remote state.
- GitHub Actions CI/CD.
- GitHub OIDC authentication to AWS.
- Trivy container vulnerability scanning.
- CloudWatch logs, metrics, alarms and dashboard.
- CPU and memory based ECS autoscaling.
- Dependency-aware readiness checks.
- Controlled database-connectivity incident and recovery.

The AWS development environment runs in `eu-west-2`.

---

## Architecture

The main runtime path is:

~~~mermaid
flowchart LR
    USER[Internet Client]
    CF[Amazon CloudFront]
    ALB[Application Load Balancer]
    ECS[Amazon ECS Fargate]
    RDS[Amazon RDS PostgreSQL]

    USER -->|HTTPS| CF
    CF -->|Origin traffic| ALB
    ALB -->|TCP 3000| ECS
    ECS -->|TCP 5432| RDS
~~~

The network is divided by responsibility:

| Tier | Main resource | Access |
|---|---|---|
| Edge | CloudFront | Public HTTPS |
| Public | Application Load Balancer | CloudFront origin traffic |
| Private application | ECS Fargate | Traffic from ALB |
| Isolated database | RDS PostgreSQL | PostgreSQL from ECS only |

ECS also communicates with AWS services through private VPC endpoints.

Detailed runtime and CI/CD diagrams are in:

**[docs/architecture.md](docs/architecture.md)**

---

## CI/CD

CareFlow uses separate Continuous Integration and Continuous Deployment workflows.

~~~text
Push / Pull Request
        |
        v
Continuous Integration
        |
        +-- Unit tests
        +-- TypeScript build
        +-- PostgreSQL migration
        +-- End-to-end smoke test
        +-- Container build
        +-- Trivy scan
        +-- Non-root verification
        |
        v
Successful CI on main
        |
        v
Continuous Deployment
        |
        +-- GitHub OIDC
        +-- Amazon ECR
        +-- ECS task definition
        +-- ECS deployment
        +-- Service stability
        +-- CloudFront health check
~~~

### Continuous Integration

`.github/workflows/ci.yml` runs on:

- Pull requests.
- Pushes to `main`.

CI starts a temporary PostgreSQL service and then:

1. Installs application dependencies.
2. Runs unit tests.
3. Compiles TypeScript.
4. Applies database migrations.
5. Runs an end-to-end smoke test.
6. Builds the production container.
7. Scans the image with Trivy.
8. Verifies the runtime uses the non-root `node` user.

If CI fails, automatic deployment does not proceed.

### Continuous Deployment

`.github/workflows/deploy.yml` starts after successful CI on `main`.

It:

1. Checks out the exact commit CI tested.
2. Authenticates to AWS through GitHub OIDC.
3. Logs in to Amazon ECR.
4. Builds and pushes a uniquely tagged image.
5. Renders a new ECS task definition.
6. Updates the ECS service.
7. Waits for service stability.
8. Verifies the public `/health/ready` endpoint.

The workflow can also be triggered manually when required.

---

## AWS authentication without stored deployment keys

GitHub Actions uses OpenID Connect rather than permanent AWS access keys.

~~~text
GitHub Actions
      |
      | OIDC token
      v
AWS IAM OIDC Provider
      |
      v
Deployment IAM Role
      |
      | Temporary credentials
      v
Amazon ECR / ECS
~~~

The deployment role is scoped to the AWS operations required to publish images and deploy the CareFlow ECS service.

Long-lived AWS deployment credentials are not stored in the repository.

---

## Infrastructure as Code

Terraform manages the AWS platform.

~~~text
infrastructure/
├── bootstrap/
│   └── Remote state resources
│
├── environments/
│   └── dev/
│
└── modules/
    ├── networking
    ├── security
    ├── container-registry
    ├── database
    ├── ecs-service
    ├── load-balancer
    ├── cloudfront
    ├── private-endpoints
    ├── github-oidc
    ├── monitoring
    └── ecs-autoscaling
~~~

Terraform manages:

- VPC networking.
- Public, private and isolated subnets.
- Security groups.
- VPC endpoints.
- ECR.
- RDS.
- ECS.
- ALB.
- CloudFront.
- IAM.
- GitHub OIDC.
- CloudWatch.
- Application Auto Scaling.

Terraform state is stored separately from the application infrastructure.

---

## Network security

The application does not rely on broad internal network access.

### CloudFront to ALB

CloudFront is the intended public entry point.

Direct ALB ingress is restricted to CloudFront origin traffic.

### ALB to ECS

~~~text
Source: ALB security group
Destination: ECS application security group
Protocol: TCP
Port: 3000
~~~

### ECS to PostgreSQL

~~~text
Source: ECS application security group
Destination: RDS database security group
Protocol: TCP
Port: 5432
~~~

RDS does not accept public traffic.

### Private AWS service access

ECS uses VPC endpoints for:

- ECR API.
- ECR Docker registry.
- CloudWatch Logs.
- Secrets Manager.
- S3.

---

## Secrets management

Database credentials are managed through AWS rather than committed to source control.

Amazon RDS manages the master password through Secrets Manager.

The ECS execution role can retrieve the required secret when an application task starts.

Credentials are not baked into:

- Source code.
- Docker images.
- GitHub workflows.
- Terraform configuration.

---

## Container security

The production image uses a multi-stage build and runs as a non-root user.

CI also runs Trivy against the built image before deployment can proceed.

### When the security gate actually blocked CI

During development, Trivy detected a critical vulnerability in a `tar` dependency bundled with npm inside the original Node.js runtime image.

npm was not required by the running application.

Rather than suppressing the finding, I changed the runtime image so that npm remains only in the build stage while the final container contains the Node runtime and application components required to run CareFlow.

CI was rerun after the change and passed.

That reduced the runtime attack surface rather than simply silencing the scanner.

---

## Application health

CareFlow exposes:

~~~text
/health/ready
~~~

The endpoint checks both application readiness and PostgreSQL connectivity.

A healthy response resembles:

~~~json
{
  "status": "healthy",
  "check": "readiness",
  "database": "reachable"
}
~~~

The deployment workflow calls this endpoint through CloudFront after ECS reports a stable service.

---

## Monitoring and autoscaling

Amazon CloudWatch provides operational visibility.

The development environment includes:

- ECS application logs.
- PostgreSQL logs.
- ECS CPU alarm.
- ECS memory alarm.
- ALB unhealthy-target alarm.
- HTTP 5xx alarm.
- RDS CPU alarm.
- RDS low-storage alarm.
- CloudWatch operational dashboard.

Application and database logs use 14-day retention in the development environment.

ECS Application Auto Scaling monitors:

- CPU utilisation.
- Memory utilisation.

Development capacity is intentionally limited to 1–2 tasks.

---

## Database connectivity incident

I used the running platform to test how it behaved when PostgreSQL connectivity disappeared.

### Baseline

Before the incident:

~~~text
HTTP 200
status: healthy
database: reachable
~~~

### Fault injection

The security-group rule allowing ECS to reach RDS on TCP `5432` was manually removed.

The existing ECS task was then stopped so the replacement task had to establish a new database connection.

### Impact

The new task could not reach PostgreSQL.

The public readiness endpoint returned:

~~~text
HTTP 503
~~~

This showed that the readiness endpoint correctly identified the failed dependency.

### Recovery

Terraform still contained the required PostgreSQL ingress rule.

A Terraform plan detected the manually introduced drift and recreated the missing rule.

After recovery:

~~~text
HTTP 200
status: healthy
database: reachable
~~~

The restored security-group rule was then verified directly in AWS.

The complete incident record is available here:

**[Database Connectivity Incident](docs/incidents/database-connectivity-incident.md)**

---

## Resilience

The ECS service uses deployment circuit-breaker protection with automatic rollback enabled.

I experimented with creating a custom automated rollback drill during development, but removed it from the final repository.

The native ECS protection remains.

I chose to keep the final project focused on the controls that improved the actual platform rather than maintaining a large workflow solely for another demonstration.

---

## Running locally

### Requirements

- Git.
- Docker.
- Docker Compose.

Clone the repository:

~~~bash
git clone https://github.com/MustafaMuk/secure-healthcare-ecs-platform.git

cd secure-healthcare-ecs-platform
~~~

Create the local environment file:

~~~bash
cp .env.example .env
~~~

Start the application:

~~~bash
docker compose up --build
~~~

Docker Compose starts PostgreSQL, applies database migrations and starts the CareFlow API.

Test readiness:

~~~bash
curl http://localhost:3000/health/ready
~~~

Stop the environment:

~~~bash
docker compose down
~~~

Remove the local database volume as well:

~~~bash
docker compose down -v
~~~

---

## Repository structure

~~~text
.
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
│
├── application/
│   ├── migrations/
│   ├── src/
│   ├── Dockerfile
│   └── package.json
│
├── docs/
│   ├── architecture.md
│   ├── data-classification.md
│   ├── decisions/
│   └── incidents/
│       └── database-connectivity-incident.md
│
├── infrastructure/
│   ├── bootstrap/
│   ├── environments/
│   └── modules/
│
├── scripts/
├── compose.yaml
└── README.md
~~~

---

## Development sizing

This is a deliberately small development environment.

| Resource | Configuration |
|---|---|
| ECS task | 0.25 vCPU / 512 MiB |
| ECS autoscaling | 1–2 tasks |
| RDS | `db.t4g.micro` |
| RDS storage | 20 GiB gp3 |
| Log retention | 14 days |
| Region | `eu-west-2` |

The environment retains components such as the ALB and private interface VPC endpoints because network isolation and private AWS service access are part of the architecture being demonstrated.

---

## What I would change for production

This project uses production-style patterns but is not presented as production-ready.

For a real production workload I would review:

### Availability

- Minimum of two ECS tasks.
- Multi-AZ RDS.
- Longer database backup retention.
- Deletion protection.
- Tested database restore procedures.

### Security

- Custom domain and ACM certificate.
- AWS WAF.
- Automated secret rotation.
- More restrictive endpoint policies.
- Centralised audit and configuration monitoring.

### Operations

- Service-level objectives.
- Latency and error-rate alerts.
- Formal alert routing.
- Capacity and load testing.
- Documented escalation procedures.

### Disaster recovery

- Defined RTO and RPO.
- Backup restoration exercises.
- Infrastructure reconstruction testing.
- Regional recovery requirements where justified.

These are production considerations, not claims about features already implemented.

---

## Key design decisions

### Why ECS Fargate?

The project focuses on container and platform engineering rather than maintaining EC2 worker nodes.

Fargate still requires decisions around networking, IAM, task definitions, health checks, scaling and deployments while removing host administration.

### Why GitHub OIDC?

Short-lived workload credentials are preferable to storing long-lived AWS deployment keys in GitHub.

### Why CloudFront in front of the ALB?

CloudFront provides the public HTTPS entry point while the ALB acts as the application origin.

### Why separate network tiers?

The load balancer, application and database have different exposure requirements.

Keeping them separate makes the permitted network paths explicit.

### Why Terraform?

Terraform provides a declared source of truth for AWS infrastructure.

The database incident demonstrated this directly when Terraform identified and repaired manually introduced network drift.

### Why scan during CI?

A critical container finding should stop the deployment before the image reaches the application service.

---

## Documentation

More detailed project material is kept outside the root README:

- [Architecture](docs/architecture.md)
- [Database connectivity incident](docs/incidents/database-connectivity-incident.md)
- [Data classification](docs/data-classification.md)
- [Project scope decision](docs/decisions/0001-project-scope.md)

---

## What this project demonstrates

CareFlow demonstrates practical experience with:

- AWS networking.
- Terraform.
- Docker.
- ECS Fargate.
- Amazon RDS.
- Amazon ECR.
- CloudFront and ALB.
- IAM.
- GitHub Actions.
- GitHub OIDC.
- Secrets Manager.
- Trivy.
- CloudWatch.
- Autoscaling.
- PostgreSQL.
- Infrastructure drift.
- Incident investigation and recovery.

More importantly, the platform can be followed end to end:

~~~text
Source change
    ↓
CI
    ↓
Security validation
    ↓
OIDC
    ↓
ECR
    ↓
ECS
    ↓
CloudFront
    ↓
Application
    ↓
PostgreSQL
~~~

That end-to-end understanding is the main purpose of the project.

---

## Project status

The development platform has been implemented and tested.

The AWS environment may be destroyed or recreated when required to control cloud costs. Terraform and the repository remain the source of truth for rebuilding it.
