terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
# S3 bucket for the tfstate. this is to make sure the tfstate file generated and push to my bucket
  backend "s3" {
    bucket         = "kaikai-bucket-2025"  # your bucket name
    key            = "aws/k8s_full/create_dns_cert/terraform.tfstate"    # path inside bucket for the state file
    region         = "us-east-1"
    dynamodb_table = "your-lock-table"              # your DynamoDB table for locking
    encrypt        = true
  }
}

# ⚠️ DO NOT hardcode credentials here in production
module "my_web" {
  source = "./module"
  
}
