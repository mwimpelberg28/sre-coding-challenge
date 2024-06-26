data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  name       = "test-cluster"
  depends_on = [module.eks.cluster_arn]

}
data "aws_eks_cluster_auth" "cluster" {
  name       = "test-cluster"
  depends_on = [module.eks.cluster_arn]
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}
