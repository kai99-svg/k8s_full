terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 1.3"   # Helm v1.x compatible with Terraform 1.13
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19"  # v2.19 works with Terraform 1.13
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }

  # S3 bucket for the tfstate. This is to make sure the tfstate file is generated and pushed to your bucket
  backend "s3" {
    bucket         = "kaikai-bucket-2025"  # your bucket name
    key            = "aws/k8s_full/create_lb_controller/terraform.tfstate"  # path inside the bucket for the state file
    region         = "us-east-1"
    dynamodb_table = "your-lock-table"  # your DynamoDB table for locking
    encrypt        = true
  }
}

# Step 1: Use remote state to access outputs from EKS setup
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "kaikai-bucket-2025"
    key    = "aws/k8s_full/k8s_infra/terraform.tfstate"  # path to EKS tfstate
    region = "us-east-1"
  }
}

# Step 2: Use outputs from the EKS remote state
data "aws_eks_cluster" "eks" {
  name = data.terraform_remote_state.eks.outputs.cluster_name # cluster name from main output
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
}

# Kubernetes provider configuration using data sources
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# AWS provider configuration
provider "aws" {
  region = "us-east-1"
}

# Include your custom module
module "my_web" {
  source = "./module"
}
