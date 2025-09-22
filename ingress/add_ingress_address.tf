terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
# S3 bucket for the tfstate. this is to make sure the tfstate file generated and push to my bucket
  backend "s3" {
    bucket         = "kaikai-bucket-2025"  # your bucket name
    key            = "aws/k8s_full/dns_add_ingress/terraform.tfstate"    # path inside bucket for the state file
    region         = "us-east-1"
    dynamodb_table = "your-lock-table"              # your DynamoDB table for locking
    encrypt        = true
  }
}

# ⚠️ DO NOT hardcode credentials here in production
data "aws_route53_zone" "selected" {
  name         = "abc1234567.dpdns.org"
}

resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "abc1234567.dpdns.org"
  type    = "A"

  alias {
    name                   = "k8s-myapp-12345678.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K" # Hosted zone ID for ALB (varies by region)
    evaluate_target_health = true
  }
}
