# Support for running your own unison.cloud cluster

## Overview

This repository contains instructions and configuration for running your own unison.cloud "Bring Your Own Cloud" (BYOC) cluster. There are multiple options based on how you'd like to deploy your cluster:

- [Docker Compose instructions](docker/README.md) for a simple deployment on a local cluster.
- [EC2 instructions](ec2/README.md) to use Terraform (or OpenTofu) to deploy to to AWS EC2 instances
- [EKS instructions](eks/README.md) to use Terraform (or OpenTofu) to deploy on a Kubernetes cluster via AWS Elastic Kubernetes Service (EKS) and deploy Unison Cloud on the resulting Kubernetes cluster.


## Scope

These configurations are intended to demonstrate minimalist deployments of unison.cloud. They are **not production-ready** but serve testing, development, and demonstration purposes. They provide an easy way to test unison.cloud in your own environment, with the expectation that you might later integrate these learnings into an existing production environment.
