########################################
# OUTPUTS
########################################
output "aws_ecr"{
  value = aws_ecr_repository.myapp.arn  
}

output "cluster_endpoint" {
  value = module.my_web.eks_cluster_endpoint #this is to refer the module output value name 
}

output "cluster_ca_certificate" {
  value = module.my_web.eks_cluster_ca_certificate
  sensitive = true
}

output "cluster_name" {
  value = module.my_web.eks_cluster_name
}

output "cluster_ca" {
  value = module.my_web.eks_cluster_ca_certificate
  sensitive = true
}

output "vpc_id" {
  value = module.my_web.vpc_id
}

output "public_subnets" {
  value = module.my_web.public_subnets
}

output "private_subnets" {
  value = module.my_web.private_subnets
}

output "oidc_role_name" {
  value = module.my_web.oidc_role_name
}