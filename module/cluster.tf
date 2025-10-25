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
  #access_config {
  #  authentication_mode = "CONFIG_MAP" # this will automatically help us to create a configmap and allow the role as master
  #  bootstrap_cluster_creator_admin_permissions = true
  #  
  #}

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_attach]  # Ensure IAM role policy attached before cluster creation
}
#data "aws_eks_cluster" "eks" {
#  name = aws_eks_cluster.eks.name
#}
#
# Get authentication token
#data "aws_eks_cluster_auth" "eks" {
#  name = aws_eks_cluster.eks.name
#}
#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.eks.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#  token                  = data.aws_eks_cluster_auth.eks.token
#}
#resource "kubernetes_config_map" "aws_auth" {
#  depends_on = [aws_eks_cluster.eks]
#  metadata {
#   name      = "aws-auth"
#   namespace = "kube-system"
#  }
#
#  data = {
#    mapRoles = yamlencode([
#      {
#        rolearn  = aws_iam_role.oidc_role.arn
#        username = "admin"
#        groups   = ["system:masters"]
#      },
#     {
#        rolearn  = aws_iam_role.eks_worker_role.arn
#        username = "bastion"
#        groups   = ["system:masters"]
#      }
#    ])
#  }
#}
# Data source to get current EKS cluster details (like endpoint, certificate)
