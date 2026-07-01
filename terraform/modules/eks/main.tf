# ADR-0006: managed control plane by default.
# This is an illustrative reference module. It bakes in a security baseline
# (secrets envelope encryption, IMDSv2, restricted-by-config API access, IRSA);
# still review IAM scope, networking, and access CIDRs before real use.

# --- Secrets envelope encryption (b1) -----------------------------------------
# Kubernetes Secrets are encrypted at rest with a KMS key. The key is optional
# to CREATE: leave var.kms_key_arn empty and the module provisions a dedicated,
# auto-rotating key; set it to bring your own. Envelope encryption itself is
# always on — it's not something a security reference should let you skip.
resource "aws_kms_key" "eks" {
  count                   = var.kms_key_arn == "" ? 1 : 0
  description             = "EKS secrets envelope encryption for ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = var.tags
}

locals {
  secrets_kms_key_arn = var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.eks[0].arn
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.cluster.id]

    # API endpoint access (b2). Private access is on so in-VPC nodes/tools reach
    # the API over the private ENIs. Public access is also on because this is a
    # reference people spin up to learn from (fully-private would break that).
    endpoint_private_access = true
    endpoint_public_access  = true

    # FOOTGUN: defaults to the entire internet so the cluster is reachable out
    # of the box. RESTRICT this to your corp/VPN egress CIDRs before real use.
    public_access_cidrs = var.public_access_cidrs
  }

  # Envelope-encrypt Secrets with the KMS key above.
  encryption_config {
    provider {
      key_arn = local.secrets_kms_key_arn
    }
    resources = ["secrets"]
  }

  # Control plane logging — all five types on for a complete audit trail
  # (required for any real security posture).
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = var.tags
}

# Security group attached to the control-plane ENIs. It defines egress only
# (allow all outbound, so the control plane can reach AWS APIs); there is
# deliberately no custom ingress rule here. Control-plane<->node traffic is
# carried by the EKS-managed cluster security group that EKS creates and
# attaches automatically, so duplicating those rules here would be redundant
# and drift-prone. Tighten egress if your network policy requires it.
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-eks-cluster-sg"
  description = "EKS control-plane ENI security group for ${var.cluster_name} (egress-only)"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound so the control plane can reach AWS APIs and nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- IRSA foundation (b5) -----------------------------------------------------
# Register the cluster's OIDC issuer as an IAM identity provider so workloads
# can assume IAM roles via projected ServiceAccount tokens (IRSA). Workload
# roles/policies are out of scope for this reference — this provides the trust
# anchor that the README's "IAM" claim implies.
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

# --- Node group launch template (b4) ------------------------------------------
# IMDSv2 required with a hop limit of 1: blocks the classic
# pod -> 169.254.169.254 -> node-role credential-theft path, since a container
# is one network hop away and can't reach the instance metadata service.
resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-node-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tags = var.tags
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  # Independent min/desired/max (b6) — no hidden desired+2 coupling. Bounds are
  # validated (min <= desired <= max) in variables.tf.
  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = [var.node_instance_type]

  # Attach the IMDSv2-hardened launch template. AMI/instance sizing stay with
  # the node group / EKS defaults; the LT only carries metadata hardening.
  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  # ADR-0001: containerd is the default EKS node runtime — no config needed here,
  # noted for clarity that this is a deliberate choice, not an accident.

  tags = var.tags
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}
