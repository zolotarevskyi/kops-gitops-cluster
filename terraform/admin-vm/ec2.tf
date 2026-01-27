resource "aws_instance" "admin_vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.kops_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.admin_vm_sg.id]
  key_name                    = "roman-mac"
  iam_instance_profile        = aws_iam_instance_profile.admin_vm_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
set -e

# --------------------------
# Hostname
# --------------------------
hostnamectl set-hostname admin-vm
echo "127.0.1.1 admin-vm" >> /etc/hosts

# --------------------------
# Create .ssh for ubuntu
# --------------------------
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# --------------------------
# Add GitHub Actions SSH key
# --------------------------
cat << 'KEY' >> /home/ubuntu/.ssh/authorized_keys
${var.github_actions_ssh_public_key}
KEY

chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# --------------------------
# System update
# --------------------------
apt-get update -y

# --------------------------
# Tools
# --------------------------
apt-get install -y \
  curl unzip ca-certificates \
  apt-transport-https gnupg lsb-release

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
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# --------------------------
# kubectl UX
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
