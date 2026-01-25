
# --------------------------
# 1. Знаходимо VPC kOps-кластера
# --------------------------
data "aws_vpc" "kops_vpc" {
  filter {
    name   = "tag:KubernetesCluster"
    values = ["k8s.asap.im"]
  }
}

# --------------------------
# 2. Беремо будь-яку subnet у цій VPC
# --------------------------
data "aws_subnets" "kops_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kops_vpc.id]
  }

  filter {
    name   = "tag:SubnetType"
    values = ["Public"]
  }
}


# --------------------------
# 3. Security Group для Admin VM
# --------------------------
resource "aws_security_group" "admin_vm_sg" {
  name        = "admin-vm-sg-roman"
  description = "Admin VM access (SSH from anywhere)"
  vpc_id      = data.aws_vpc.kops_vpc.id

  ingress {
    description = "SSH from anywhere (0.0.0.0/0)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "admin-vm-sg-roman"
  }
}

# --------------------------
# 4. Admin EC2 instance
# --------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "admin_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.kops_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.admin_vm_sg.id]
  key_name               = "roman-mac"

  associate_public_ip_address = true   # ← рекомендую додати

  tags = {
    Name = "k8s-admin-vm-roman"
    Role = "kubernetes-admin-roman"
  }
}
