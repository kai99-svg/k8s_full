########################################
# OUTPUTS
########################################

output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_ca_certificate" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

output "vpc_id" {
  value = aws_vpc.first_vpc.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "oidc_role_name" {
  value = aws_iam_role.oidc_role.name
}

output "oidc_role_arn" {
  value = aws_iam_role.oidc_role.arn
}
