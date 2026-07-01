# Example wiring of the eks module for a single environment.
# Replace vpc_id/subnet_ids with real values or a VPC module before applying.
# All environment-specific values live in variables.tf (with sane defaults) —
# override via a .tfvars file per environment, not by editing this file.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
}
