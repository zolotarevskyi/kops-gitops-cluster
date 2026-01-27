# --------------------------
# VPC from kOps
# --------------------------
data "aws_vpc" "kops_vpc" {
  filter {
    name   = "tag:KubernetesCluster"
    values = ["k8s.asap.im"]
  }
}

# --------------------------
# Public subnet
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
# Security Group
# --------------------------
resource "aws_security_group" "admin_vm_sg" {
  name   = "admin-vm-sg-roman"
  vpc_id = data.aws_vpc.kops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------
# Ubuntu AMI
# --------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --------------------------
# Admin VM
# --------------------------
resource "aws_instance" "admin_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.kops_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.admin_vm_sg.id]

  key_name             = "roman-mac"
  iam_instance_profile = aws_iam_instance_profile.admin_vm_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
set -e

hostnamectl set-hostname admin-vm
echo "127.0.1.1 admin-vm" >> /etc/hosts

mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

cat << 'KEY' >> /home/ubuntu/.ssh/authorized_keys
${var.github_actions_ssh_public_key}
KEY

chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

apt-get update -y
apt-get install -y curl unzip ca-certificates

EOF

  tags = {
    Name = "k8s-admin-vm"
  }
}
