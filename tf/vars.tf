variable "vpc_name" {
  default = "test-vpc"
}

variable "azs" {
  default = ["us-west-2a", "us-west-2b"]
}

variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_vpn_gateway" {
  type    = bool
  default = false
}

variable "tags" {
  default = {
    project   = "test"
    terraform = "true"
  }
}

variable "cluster_name" {
  default = "test-cluster"
}

variable "eks_version" {
  default = "1.28"
}

variable "instance_size" {
  default = "t3.medium"
}

variable "node_group_name" {
  default = "test-self-ng"
}

variable "platform" {
  default = "test"
}

variable "eks_ami" {
  default = "ami-05d211d1143f6774d"
}

variable "asg_size" {
  default = "2"
}

variable "key_name" {
  default = "mw-us-west-2-keypair"
}

variable "cluster_endpoint_public_access" {
  default = true
}

variable "create_aws_auth_configmap" {
  default = true
}

variable "manage_aws_auth_configmap" {
  default = true
}

variable "ec2_name"{
  default = "jenkins-0"
}

variable "volume_size"{
  default = 50
}

variable "volume_throughput"{
  default = 200
}