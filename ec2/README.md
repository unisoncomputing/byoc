# OpenTofu / Terraform definition for creating EC2 instances to run unison.cloud

# Overview

This repository contains a Terraform (or OpenTofu) definition for creating EC2 instances to run a BYOC (Bring Your Own Cloud) instance of [unison.cloud](https://unison.cloud).

## Scope

This repository creates:

- An AWS VPC with public and private subnets. [vpc.tf](vpc.tf)
- EC2 instances in an Auto Scaling Group running the unison.cloud application. [unison.tf](unison.tf)
- An Application Load Balancer for routing traffic to unison.cloud instances. [loadbalancer.tf](loadbalancer.tf)
- A bastion host for secure SSH access to the instances. [bastion.tf](bastion.tf)
- Proxy instances for additional routing capabilities. [proxy.tf](proxy.tf)
- A DynamoDB table for storing unison.cloud data using unison.cloud's `Storage` ability. [dynamo.tf](dynamo.tf)
- S3 buckets for storing unison.cloud services, and storing blobs using Unison Cloud's `Blob` storage. [s3.tf](s3.tf)
- IAM roles and policies for EC2 instances to access AWS services. [iam.tf](iam.tf)

This is intended to demonstrate a minimalist deployment of unison.cloud on EC2. It is **not production-ready** but serves testing, development, and demonstration purposes. This provides an easy way to test unison.cloud in your AWS account with EC2 instances.

# Prerequisites

- [Terraform](https://www.terraform.io) / [OpenTofu](https://opentofu.org)
    Terraform is a tool for building infrastructure declaratively. OpenTofu is a recent fork of Terraform under a more free license. This repository is compatible with both tools.

    * [Install OpenTofu](https://opentofu.org/docs/intro/install/)

- AWS CLI
    AWS CLI must be installed and configured with credentials sufficient to create all the various resources in AWS (VPCs, EC2, S3 buckets, etc.) AWS CLI can be installed following [Amazon's instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions). MacOs users can also install it via Homebrew with `brew install awscli`.

    You can configure the AWS CLI by running `aws configure` and providing your AWS Access Key ID, Secret Access Key, and the default region.

<details>
<summary>Notes for Nix users</summary>
## Nix

If you use [Nix](https://nixos.org), there is a nix flake definition that installs OpenTofu and aws cli. You can launch a shell with all the tools by running `nix develop #eks` in the parent directory, or use [direnv](https://direnv.net/) with `use flake #eks` in a `.envrc` file to automatically load the environment when you `cd` into the directory.
</details>

## Deploying to AWS

### terraform.tfvars

You must create a `terraform.tfvars` file containing variables specific to your cluster. [variables.tf](variables.tf) contains all the variables you can set to customize the deployment. Many of these variables have defaults for a basic deployment that are optional in `terraform.tfvars`—some don't have defaults and must be set.

There is a [terraform.tfvars.example](terraform.tfvars.example) file that contains all of the possible variables, you can use as a reference when creating your `terraform.tfvars`.

#### Required variables:

##### `aws_region`

The AWS region to deploy the cluster in. Examples include `us-west-2`, `us-east-1`, etc. This is the region where all the resources will be created.

You can find a complete list of zones and regions in the [AWS documentation](https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html).

##### `aws_availability_zones`

A list of availability zones to use for the VPC. This should be a list of two or more availability zones in the region you are deploying to. For example, `["us-west-2a", "us-west-2b"]`. You must include at least two availability zones for the load balancer to work across multiple AZs.

You can find a complete list of zones and regions in the [AWS documentation](https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html).

##### `cluster_name`

The name of the cluster, which should match the name you used to create a `Cluster.Id`. This will be used to name the EC2 instances and the DynamoDB table. It must be a valid DNS subdomain, meaning it must consist of only lowercase letters, numbers, and hyphens, and must start and end with a letter or number.

### Running Terraform

Once you have created the `terraform.tfvars` file, you can run OpenTofu to create the infrastructure:

```bash
$ tofu init
$ tofu apply
```

`tofu init` will inspect the configuration and download any necessary terraform modules.
`tofu apply` will create all the needed resources in your AWS account, this might take 15-20 minutes. The script will output important information including the load balancer DNS name and bastion host IP.

### Using the cluster
The script will generate a `outputs/cluster_setup.u` file that that contains a `ClientConfig` which you can use to deploy services and
run jobs against your cluster. 

You can save this output into your scratch file, or load this file into a ucm session with `> load /path/to/outputs/cluster_setup.u`. and then you should be able to `> run myJob` to launch a job on your new cluster!


## Tearing down the infrastructure

To tear down all the EC2 instances and associated resources, run:

```bash
$ tofu destroy
```

This will delete all the resources created by the Terraform definition.

