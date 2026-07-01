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
}

variable "node_instance_type" {
  type    = string
  default = "m6i.large"
}

variable "node_desired_size" {
  type    = number
  default = 3
}
