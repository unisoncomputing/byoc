# Support for running your own unison.cloud cluster

## Overview

This repository contains instructions and configuration for running your own unison.cloud "Bring Your Own Cloud" (BYOC) cluster. It is a [repository template](https://gitprotect.io/blog/how-to-use-github-repository-templates/) that you are intended to create a new repository from. There are multiple options based on how you'd like to deploy your cluster:

- [Docker Compose instructions](docker/README.md) for a simple deployment on a local cluster.
- [EC2 instructions](ec2/README.md) to use Terraform (or OpenTofu) to deploy to to AWS EC2 instances
- [EKS instructions](eks/README.md) to use Terraform (or OpenTofu) to deploy on a Kubernetes cluster via AWS Elastic Kubernetes Service (EKS) and deploy Unison Cloud on the resulting Kubernetes cluster.

## Prerequisites

In order to create and use your own Unison Cloud cluster, you will need:

- A [unison.cloud](https://unison.cloud) account with an [active subscription](https://www.unison.cloud/signup/?plan=Starter).

- UCM must be installed, you can see our [quickstart guide](https://www.unison-lang.org/docs/quickstart/) for setting that up.

- You have to have recently run `auth.login` inside UCM.

- You have [registered a Unison Cloud BYOC cluster](#register-a-byoc-cluster).

## Scope

These configurations are intended to demonstrate minimalist deployments of unison.cloud. They are **not production-ready** but serve testing, development, and demonstration purposes. They provide an easy way to test unison.cloud in your own environment, with the expectation that you might later integrate these learnings into an existing production environment.

## Register a BYOC cluster

You can register a BYOC cluster by calling the [BYOC.createCluster](https://share.unison-lang.org/@unison/cloud/code/releases/26.0.0/latest/terms/BYOC/createCluster) command in the [Unison Cloud client](https://share.unison-lang.org/@unison/cloud).
