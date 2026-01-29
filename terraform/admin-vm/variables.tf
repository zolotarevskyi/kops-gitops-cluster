variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "kops_state_bucket" {
  type        = string
  description = "S3 bucket where Kops stores the cluster state"
}

variable "kops_cluster_name" {
  type        = string
  description = "kOps cluster name, e.g. k8s.asap.im"
}

variable "kops_subdomain" {
  type        = string
  description = "Hosted zone for the subdomain, e.g., k8s.example.com"
}

variable "github_actions_ssh_public_key" {
  description = "Public SSH key for GitHub Actions"
  type        = string
}

