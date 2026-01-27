# --------------------------
# Ubuntu 22.04 AMI
# --------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --------------------------
# Security Group for Admin VM
# --------------------------
resource "aws_security_group" "admin_vm_sg" {
  name   = "admin-vm-sg-roman"
  vpc_id = data.aws_vpc.kops_vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name              = "admin-vm-sg-roman"
    KubernetesCluster = "k8s.asap.im"
  }
}

# --------------------------
# Admin VM (GitOps entrypoint)
# --------------------------
resource "aws_instance" "admin_vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.kops_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.admin_vm_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.admin_vm_profile.name
  associate_public_ip_address = true
  key_name                    = "roman-mac"

  user_data = <<-EOF
#!/bin/bash
set -e

# --------------------------
# Hostname (permanent)
# --------------------------
hostnamectl set-hostname admin-vm
echo "127.0.1.1 admin-vm" >> /etc/hosts

# --------------------------
# SSH for GitHub Actions
# --------------------------
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

cat << 'KEY' > /home/ubuntu/.ssh/authorized_keys
${var.github_actions_ssh_public_key}
KEY

chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# --------------------------
# System tools
# --------------------------
apt-get update -y
apt-get install -y \
  curl \
  unzip \
  ca-certificates \
  apt-transport-https \
  gnupg \
  lsb-release

# --------------------------
# kubectl
# --------------------------
curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl

# --------------------------
# kops
# --------------------------
curl -LO https://github.com/kubernetes/kops/releases/download/v1.29.0/kops-linux-amd64
chmod +x kops-linux-amd64
mv kops-linux-amd64 /usr/local/bin/kops

# --------------------------
# AWS CLI
# --------------------------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
./aws/install

# --------------------------
# kubectl UX (ubuntu user)
# --------------------------
sudo -u ubuntu bash -c "echo 'alias k=kubectl' >> ~/.bashrc"
sudo -u ubuntu bash -c "echo 'source <(kubectl completion bash)' >> ~/.bashrc"

EOF

  tags = {
    Name              = "k8s-admin-vm-roman"
    Role              = "kubernetes-admin-roman"
    KubernetesCluster = "k8s.asap.im"
  }
}
