# Secure Healthcare ECS Platform

A production-style healthcare appointment platform deployed to AWS ECS Fargate using Terraform and GitHub Actions.

> **Demonstration platform — synthetic data only.**
> This project does not contain real patient, clinical or personally identifiable information.

## Project goals

This project demonstrates:

- AWS networking across multiple Availability Zones
- Container deployment using Amazon ECS Fargate
- Infrastructure provisioning using Terraform
- Private PostgreSQL storage using Amazon RDS
- Secure secret handling using AWS Secrets Manager
- Continuous integration and deployment using GitHub Actions
- Temporary AWS credentials using GitHub OIDC
- Monitoring, logging and alerting using Amazon CloudWatch
- Failed deployment testing and automated rollback
- Incident investigation, recovery and operational documentation

## Planned architecture

Internet traffic will enter through an Application Load Balancer in public subnets.

The application will run as ECS Fargate tasks inside private application subnets.

Amazon RDS PostgreSQL will run inside isolated database subnets and accept connections only from the ECS application security group.

## Healthcare operations connection

The project applies lessons from healthcare and EPR support:

- Service availability
- Controlled releases
- Auditability
- Incident communication
- Recovery verification
- Protection of sensitive systems
- Clear operational runbooks

## Status

Project foundation in progress.
