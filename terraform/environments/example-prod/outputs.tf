output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

# Re-exported (sensitive) so a kubeconfig can be built from environment outputs
# alone: endpoint + name + CA data.
output "cluster_certificate_authority_data" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "IAM OIDC provider ARN for IRSA."
}
