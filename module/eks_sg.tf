# Security Group for the EKS VPC Endpoint
####Yes — if you set it up correctly, using a VPC Interface Endpoint for EKS means your EKS API is only accessible privately from within your VPC, not over the public internet.####
# For production, aim for:
# - endpoint_public_access = false
# - endpoint_private_access = true
# - Use VPC endpoint
# - Use private subnets only for security
resource "aws_security_group" "eks_sg" {
  name        = "eks-sg"
  description = "Allow inbound from worker nodes"
  vpc_id      = aws_vpc.first_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.100.0/24"]  # or security group of worker nodes
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
