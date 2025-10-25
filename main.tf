terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    
  }
  
# S3 bucket for the tfstate. this is to make sure the tfstate file generated and push to my bucket
  
  backend "s3" {
    bucket         = "kaikai-bucket-2025"  # your bucket name
    key            = "aws/k8s_full/k8s_infra/terraform.tfstate"    # path inside bucket for the state file
    region         = "us-east-1"
    use_lockfile   = true             # your DynamoDB table for locking
    encrypt        = true
  }
}

# ⚠️ DO NOT hardcode credentials here in production
provider "aws" {
  region     = "us-east-1"
}
# this is to create the dynamotable for the lock
#resource "aws_dynamodb_table" "terraform_locks" {
#  name         = "terraform-locks"
#  billing_mode = "PAY_PER_REQUEST"
#  hash_key     = "LockID"
#
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}
module "my_web" {
  source = "./module"
# public subnet value list 
  public_subnets = [
    {
      cidr_block        = "10.0.100.0/24"
      availability_zone = "us-east-1a"
    },
    {
      cidr_block        = "10.0.150.0/24"
      availability_zone = "us-east-1b"
    }
  ]
# private subnet value list 
  private_subnets = [
    {
      cidr_block        = "10.0.180.0/24"
      availability_zone = "us-east-1c"
    },
    {
      cidr_block        = "10.0.200.0/24"
      availability_zone = "us-east-1d"
    }
  ]
# eks addon value list 
  eks_addon = ["vpc-cni","coredns","kube-proxy","aws-ebs-csi-driver"]

  
}
########################################
# OUTPUTS
########################################

output "cluster_endpoint" {
  value = module.my_web.eks_cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.my_web.eks_cluster_ca_certificate
}

output "cluster_name" {
  value = module.my_web.eks_cluster_name
}

output "cluster_ca" {
  value = module.my_web.eks_cluster_ca_certificate
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

output "oidc_role_arn" {
  value = module.my_web.oidc_role_arn
}
