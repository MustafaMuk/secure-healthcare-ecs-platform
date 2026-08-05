# ADR 0001 — Project Scope

## Status

Accepted

## Context

The project must demonstrate practical AWS, Terraform, ECS, Docker, CI/CD, networking, security, monitoring and incident-response skills.

It must also connect to previous experience supporting healthcare and EPR applications without processing real healthcare information.

## Decision

Build a healthcare-inspired appointment platform using synthetic data.

The initial application will be a modular service rather than a complex microservices architecture.

AWS ECS Fargate will run the application, Amazon RDS PostgreSQL will store data and Terraform will provision the infrastructure.

## Reasoning

A modular application keeps the project understandable while still allowing strong demonstrations of:

- Container operations
- Cloud networking
- Database connectivity
- Secure configuration
- Deployment automation
- Monitoring
- Failure recovery

## Consequences

The project will prioritise operational quality and evidence over unnecessary application complexity.
