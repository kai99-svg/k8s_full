# -----------------------------
# IAM Role for EKS Worker Nodes
# -----------------------------
resource "aws_iam_role" "eks_worker_role" {
  name = "eks-node-role"

  # Trust policy allowing EC2 instances to assume this role
  # This enables worker nodes (EC2 instances) to interact with AWS services on behalf of EKS
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  # Only EC2 instances are allowed to assume this role
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach essential AWS managed policies to the worker node role for EKS functionality

resource "aws_iam_role_policy_attachment" "eks_worker_attach" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  # Provides permissions required by EKS worker nodes to communicate with the control plane
}

resource "aws_iam_role_policy_attachment" "eks_worker_attach_ssm_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  # Grants permissions for Systems Manager (SSM) to manage and connect to EC2 instances
}

resource "aws_iam_role_policy_attachment" "eks_worker_attach_CR_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  # Allows worker nodes to pull container images from Amazon ECR
}

resource "aws_iam_role_policy_attachment" "eks_worker_attach_CNI_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  # Allows the Amazon VPC CNI plugin to manage networking for worker nodes
}
resource "aws_iam_role_policy_attachment" "eks_worker_attach_CSI_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
resource "aws_iam_role_policy_attachment" "eks_worker_attach_SSMManagedInstanceCore_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# -----------------------------
# IAM Instance Profile for Worker Nodes
# -----------------------------
resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "eks-node-profile"
  role = aws_iam_role.eks_worker_role.name
  # EC2 instances assume this instance profile, which contains the IAM role above
}

# -----------------------------
# Launch Template for EKS Worker Nodes
# -----------------------------
resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "my_node"

  node_role_arn = aws_iam_role.eks_worker_role.arn

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }
  subnet_ids = aws_subnet.private[*].id
  instance_types = ["c7i-flex.large"]
  
  update_config {
    max_unavailable = 1
  }
  tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "owned"
    "Name" = "eks-nodegroup"
  }
  depends_on = [aws_eks_cluster.eks]
}

resource "aws_iam_role" "self_hosted" {
  name = "self-hosted-role"

  # Trust policy allowing EC2 instances to assume this role
  # This enables worker nodes (EC2 instances) to interact with AWS services on behalf of EKS
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  # Only EC2 instances are allowed to assume this role
      }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_worker_attach" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  # Provides permissions required by EKS worker nodes to communicate with the control plane
}
resource "aws_iam_role_policy_attachment" "eks_worker_attach" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  # Provides permissions required by EKS worker nodes to communicate with the control plane
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  # Grants permissions for Systems Manager (SSM) to manage and connect to EC2 instances
}

resource "aws_iam_role_policy_attachment" "eks_worker_attach_CR_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  # Allows worker nodes to pull container images from Amazon ECR
}
resource "aws_iam_role_policy_attachment" "eks_worker_attach_SSMManagedInstanceCore_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# 10. IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.self_hosted.name  # <--- this is wrong, .arn is full ARN, you need .name
}

resource "aws_instance" "foo" {
  ami           = "ami-0360c520857e3138f" # us-west-2
  instance_type = "c7i-flex.large"
  vpc_security_group_ids = [aws_security_group.worker_sg.id]

   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name # this is to give the ec2 attach with role

  subnet_id = aws_subnet.public[0].id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo apt install unzip
              sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo unzip awscliv2.zip
              sudo ./aws/install
              sudo curl -LO "https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.4/2025-08-20/bin/linux/amd64/kubectl"
              sudo chmod +x kubectl
              sudo mv kubectl /usr/local/bin/
              sudo curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
              EOF

  tags= {
    Name = "mybastion"
    value = "test"
  }

}