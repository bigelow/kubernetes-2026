# Example wiring of the eks module for a single environment.
# Replace vpc_id/subnet_ids with real values or a VPC module before applying.
# All environment-specific values live in variables.tf (with sane defaults) —
# override via a .tfvars file per environment, not by editing this file.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # v6 is the current major line. Its headline change (per-resource region
      # support) is additive; none of the EKS / node group / launch template /
      # IAM / KMS resources used here have breaking changes from v5, so this is
      # a clean constraint bump (see the v6 upgrade guide).
      version = "~> 6.0"
    }
  }

  # State backend: local state is fine for kicking the tires, NOT for anything
  # real (no locking, no sharing, easy to lose). Fill in and uncomment for a
  # remote S3 backend with DynamoDB locking:
  #
  # backend "s3" {
  #   bucket         = "REPLACE-ME-tfstate-bucket"
  #   key            = "eks/example-prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "REPLACE-ME-tfstate-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  # Consistent tagging on every resource this provider manages (b7). Resource-
  # level tags (the module's `tags` var) merge on top of these.
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = var.cluster_name
      Project     = "k8s-reference-architecture"
    }
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  node_instance_type  = var.node_instance_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  public_access_cidrs = var.public_access_cidrs
  kms_key_arn         = var.kms_key_arn

  # Module-level tags merge on top of the provider default_tags above.
  tags = { Component = "eks" }
}
