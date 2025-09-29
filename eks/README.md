# OpenTofu / Terraform definition for creating an EKS cluster to run unison.cloud

# Overview

This repository contains a Terraform (or OpenTofu) definition for creating an EKS cluster to run a BYOC (Bring Your Own Cloud) instance of [unison.cloud](https://unison.cloud).

## Scope

This repository creates:

- An AWS VPC for a Kubernetes cluster to run in. [vpc.tf](vpc.tf)
- An EKS (Kubernetes) cluster with the unison.cloud application deployed. [eks.tf](eks.tf)
- A DynamoDB table for storing unison.cloud data using unison.cloud's `Storage` ability. [dynamo.tf](dynamo.tf)
- S3 buckets for storing unison.cloud services, and storing blobs using Unison Cloud's `Blob` storage. [s3.tf](s3.tf)

This is intended to demonstrate a minimalist deployment of unison.cloud. It is **not production-ready** but serves testing, development, and demonstration purposes. This provides an easy way to test unison.cloud in your AWS account, with the expectation that you might later integrate these learnings into an existing Kubernetes deployment.

# Prerequisites

- [Terraform](https://www.terraform.io) / [OpenTofu](https://opentofu.org)
    Terraform is a tool for building infrastructure declaratively. OpenTofu is a recent fork of Terraform under a more free license. This repository is compatible with both tools.

    * [Install OpenTofu](https://opentofu.org/docs/intro/install/)

- AWS CLI
    AWS CLI must be installed and configured with credentials sufficient to create all the various resources in AWS (VPCs, EKS, S3 buckets, etc.) AWS CLI can be installed following [Amazon's instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions). MacOs users can also install it via Homebrew with `brew install awscli`.

    You can configure the AWS CLI by running `aws configure` and providing your AWS Access Key ID, Secret Access Key, and the default region.

- kubectl
    [kubectl](https://kubernetes.io/docs/tasks/tools/) is the command line tool for interacting with Kubernetes clusters. It must be installed to launch the unison containers into the EKS environment.
    * [Install kubectl on MacOs](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/)
    * [Install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
    * [Install kubectl on Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)


<details>
<summary>Notes for Nix users</summary>
## Nix

If you use [Nix](https://nixos.org), there is a nix flake definition that installs OpenTofu, aws, and kubectl. You can launch a shell with all the tools by running `nix develop #eks` in this repository, or use [direnv](https://direnv.net/) with `use flake #eks` in a `.envrc` file to automatically load the environment when you `cd` into the directory.
</details>

## Deploying to AWS

### terraform.tfvars

[variables.tf](variables.tf) is where all of the variables for the deployment are defined. The values are set in [terraform.tfvars](terraform.tfvars). *You must* edit this file to set the `cluster_name` before deploying.

#### Required variables:

##### `aws_region`

The AWS region to deploy the cluster in. Examples include `us-west-2`, `us-east-1`, etc. This is the region where all the resources will be created.

You can find a complete list of zones and regions in the [AWS documentation](https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html).

##### `aws_availability_zones`

A list of availability zones to use for the VPC. This should be a list of two or more availability zones in the region you are deploying to. For example, `["us-west-2a", "us-west-2b"]`. You must include at least two availability zones for the load balancer to work across multiple AZs.

You can find a complete list of zones and regions in the [AWS documentation](https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html).

##### `cluster_name`

The name of the cluster, which should match the name you used to create a `Cluster.Id`. This will be used to create the EKS cluster and the DynamoDB table. It must be a valid DNS subdomain, meaning it must consist of only lowercase letters, numbers, and hyphens, and must start and end with a letter or number.

### Running Terraform

Once you have created the `terraform.tfvars` file, you can run OpenTofu to create the cluster:

```bash
$ tofu init
$ tofu apply
```
`tofu init` will inspect the configuration and download any necessary terraform modules.
`tofu apply` will create all the needed resources in your AWS account, this might take 20-30 minutes. Upon successful completion, `tofu apply` will display all out the "outputs" which can later be retrieved by running `tofu output`.

### Using the cluster
The script will generate a `outputs/cluster_setup.u` file that that contains a `ClientConfig` which you can use to deploy services and
run jobs against your cluster. 

You can save this output into your scratch file, or load this file into a ucm session with `> load /path/to/outputs/cluster_setup.u`. and then you should be able to `> run myJob` to launch a job on your new cluster!

<details>
<summary>Connecting to the EKS Cluster with kubectl</summary>

## Connecting to the EKS Cluster with kubectl

Once the cluster is up, you can connect to it using kubectl. First, update your kubeconfig:

```bash
$ aws eks update-kubeconfig --region $REGION --name $CLUSTERNAME
```

After which, you should be able to see the cluster:

```bash

$ kubectl cluster-info
```

## Checking the pods

You can check the status of the pods in the cluster using kubectl:

```bash
$ kubectl get pods
NAME                                 READY   STATUS    RESTARTS   AGE
unison-deployment-59d778f878-c8zc6   1/2     Running   0          4m12s
unison-deployment-59d778f878-n5wdt   1/2     Running   0          4m12s
unison-deployment-59d778f878-xng75   1/2     Running   0          4m12s
unison-deployment-59d778f878-zmlxd   1/2     Running   0          4m12s
```

You can check the logs of a specific pod:

```bash
$ kubectl logs unison-deployment-59d778f878-c8zc6
```
</details>


## Tearing down the cluster

To tear down the cluster and all associated resources, run:

```bash
$ tofu destroy
```
This will delete all the resources created by the Terraform definition.


