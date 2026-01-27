# --------------------------
# Existing VPC created by kOps
# --------------------------
data "aws_vpc" "kops_vpc" {
  filter {
    name   = "tag:KubernetesCluster"
    values = ["k8s.asap.im"]
  }
}

# --------------------------
# Public subnets in this VPC
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
