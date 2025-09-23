# Create the EKS cluster itself
resource "aws_eks_cluster" "eks" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn  # Use the IAM role created above for control plane permissions

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id # Subnets for the cluster
    endpoint_public_access  = false   # Allow public access to the API endpoint
    endpoint_private_access = true   # Allow private access to the API endpoint
    security_group_ids = [aws_security_group.eks_sg.id]
  }
  access_config {
    authentication_mode = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_attach]  # Ensure IAM role policy attached before cluster creation
}


resource "aws_eks_auth" "github_actions_role" {
  cluster_name = "my-eks-cluster"
  rolearn      = "arn:aws:iam::279205476473:role/github-actions-deploy-role"

  # Kubernetes RBAC groups to assign to this role
  username     = "github-actions-deploy"
  groups       = [
    "system:masters"  # grants cluster admin access
  ]
}

# Data source to get current EKS cluster details (like endpoint, certificate)
