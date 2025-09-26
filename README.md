# Support for running your own unison.cloud cluster

## Overview

This repository contains instructions and configuration for running your own unison.cloud "Bring Your Own Cloud" (BYOC) cluster. There are multiple options based on how you'd like to deploy your cluster:

- [Docker Compose instructions](docker/README.md) for a simple deployment on a local cluster.
- [EKS instructions](eks/README.md) to use Terraform (or OpenTofu) to deploy on a Kubernetes cluster via AWS Elastic Kubernetes Service (EKS).


## Scope

These configurations are intended to demonstrate minimalist deployments of unison.cloud. They are **not production-ready** but serve testing, development, and demonstration purposes. They provide an easy way to test unison.cloud in your own environment, with the expectation that you might later integrate these learnings into an existing production environment.

## Prerequisites

### Cluster name

To register a Unison Cloud cluster, you'll need a cluster name. You can come up with your own or have one generated for you, but it must be unique across all Unison Cloud clusters. It should be a valid DNS subdomain, meaning it must consist of only lowercase letters, numbers, and hyphens, and must start and end with a letter or number.

### Register a BYOC cluster

See [the Unison Cloud BYOC website](https://www.unison.cloud/byoc/) for more info.


### Cluster token

Before deploying your cluster you will need a cluster token to authenticate your nodes with the Unison Cloud control plane. You will receive one of these when your cluster is registered.
