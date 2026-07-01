output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
  # Base64 CA cert used to build a kubeconfig; marked sensitive so it isn't
  # echoed in plan/apply console output.
  sensitive = true
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.oidc.arn
  description = "IAM OIDC provider ARN for IRSA — bind workload IAM roles to this."
}
