variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
  # EKS offers 1.36 on standard support (verified against the AWS EKS
  # "standard support" version list, July 2026), so this default is applyable.
  # The repo's Kubernetes manifests target upstream v1.36; this default tracks
  # what EKS actually offers — bump only to a version EKS lists as supported.
  description = "Kubernetes minor version (ADR-0006: managed control plane)."
}

variable "vpc_id" {
  type        = string
  description = "VPC to deploy the cluster into."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the control plane ENIs and node groups."
}

variable "node_instance_type" {
  type    = string
  default = "m6i.large"
}

variable "node_desired_size" {
  type    = number
  default = 3

  validation {
    condition     = var.node_desired_size >= var.node_min_size && var.node_desired_size <= var.node_max_size
    error_message = "node_desired_size must be between node_min_size and node_max_size (inclusive)."
  }
}

variable "node_min_size" {
  type        = number
  default     = 1
  description = "Minimum node count for the managed node group."
}

variable "node_max_size" {
  type        = number
  default     = 5
  description = "Maximum node count for the managed node group."

  validation {
    condition     = var.node_max_size >= var.node_min_size
    error_message = "node_max_size must be >= node_min_size."
  }
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
  # FOOTGUN: the default exposes the public API endpoint to the whole internet
  # so the reference is reachable out of the box. Restrict to corp/VPN CIDRs
  # for anything real. See endpoint_public_access in main.tf.
  description = "CIDRs allowed to reach the public API server endpoint."
}

variable "kms_key_arn" {
  type    = string
  default = ""
  # Empty (default) => the module creates a dedicated, auto-rotating KMS key
  # for Secrets envelope encryption. Set to an existing key ARN to bring your
  # own. Encryption is always enabled either way.
  description = "External KMS key ARN for Secrets envelope encryption; empty means create one."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags merged onto all taggable resources in this module."
}
