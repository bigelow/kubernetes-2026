variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.36"
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
}
