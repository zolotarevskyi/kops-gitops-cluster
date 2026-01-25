# --------------------------
# IAM Role for Admin VM
# --------------------------
resource "aws_iam_role" "admin_vm_role" {
  name = "k8s-admin-vm-role-roman"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name              = "k8s-admin-vm-role-roman"
    KubernetesCluster = "k8s.asap.im"
  }
}

# --------------------------
# Attach policies (kOps needs wide access)
# --------------------------
resource "aws_iam_role_policy_attachment" "admin_vm_policy" {
  role       = aws_iam_role.admin_vm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --------------------------
# Instance Profile
# --------------------------
resource "aws_iam_instance_profile" "admin_vm_profile" {
  name = "k8s-admin-vm-profile-roman"
  role = aws_iam_role.admin_vm_role.name
}
