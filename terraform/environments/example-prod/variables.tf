variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_name" {
  type        = string
  default     = "example-prod"
  description = "EKS cluster name. Override per environment (e.g. via a .tfvars file) rather than editing main.tf."
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
  # EKS lists 1.36 on standard support (verified July 2026); the repo manifests
  # target upstream v1.36. Keep this in step with what EKS actually offers.
  description = "Kubernetes minor version for the EKS control plane."
}

variable "node_instance_type" {
  type    = string
  default = "m6i.large"
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 5
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
  # FOOTGUN (see module): open to the whole internet by default so the
  # reference is reachable. Restrict to your corp/VPN CIDRs before real use.
  description = "CIDRs allowed to reach the public API server endpoint."
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "External KMS key ARN for Secrets encryption; empty means the module creates one."
}
