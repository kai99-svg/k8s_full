# Define the IAM Role for the EKS Cluster control plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  # Trust policy allowing EKS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the managed AWS policy required for EKS Cluster control plane
resource "aws_iam_role_policy_attachment" "eks_cluster_attach" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_csi_attach" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


# ------------------------------------------------------------------------------------------------------------#

# Create an IAM OIDC Provider for the cluster to enable service account IAM roles
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  depends_on = [aws_eks_cluster.eks]  # Wait for cluster creation before creating OIDC provider

  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer  # OIDC issuer URL from the cluster
  client_id_list  = ["sts.amazonaws.com"]  # Allowed client ID for the provider# 
  thumbprint_list = ["63462dda480d8b900e0a7dbfaf6238a62ba4fce0"]  # Thumbprint of the OIDC provider's certificate
}

# Create an IAM Role that Kubernetes service accounts can assume using OIDC federation
resource "aws_iam_role" "oidc_role" {
  name = "eks-oidc-role"

  # Trust policy allows the role to be assumed by the specific service account 'aws-node' in 'kube-system' namespace# 
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc_provider.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          # The sub claim must match this service account
          "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" : [
                        "system:serviceaccount:kube-system:aws-node",
                        "system:serviceaccount:kube-system:ebs-csi-controller-sa",
                        "system:serviceaccount:kube-system:ebs-csi-node-sa",
                        "system:serviceaccount:kube-system:aws-load-balancer-controller"
                    ]
        }
      }
    }]
  })
}
# Attach the Amazon EKS CNI Policy to the OIDC IAM role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  # Allows CNI plugin to manage networking
}
resource "aws_iam_role_policy_attachment" "csi" {
  role       = aws_iam_role.oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"  # Allows CNI plugin to manage networking
}
# ------------------------------------------------------------------------------------------------------------#

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: arn:aws:iam::279205476473:role/eks-node-role
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: arn:aws:iam::279205476473:role/eks-node-role
  username: admin
  groups:
    - system:masters
EOF
  }
}

resource "aws_eks_addon" "vpc_cni" {
  count = length(var.eks_addon)
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = var.eks_addon[count.index]
  service_account_role_arn = aws_iam_role.oidc_role.arn

  #service_account_role_arn = contains(
  # ["vpc-cni", "aws-ebs-csi-driver"],
  #  var.eks_addon[count.index]
  #) ? aws_iam_role.oidc_role.arn : null

  #It checks if the current addon (var.eks_addon[count.index]) is in the list ["vpc-cni", "aws-ebs-csi-driver"].

  #If yes (meaning this addon supports IRSA), it assigns aws_iam_role.oidc_role.arn to service_account_role_arn.

  #If no, it assigns null, which means Terraform won't set the service_account_role_arn for addons that don't support it (like coredns or kube-proxy).
}
