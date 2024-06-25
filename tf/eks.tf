module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                   = var.cluster_name
  cluster_version                = var.eks_version
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }


  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  cluster_endpoint_private_access = true
  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    instance_types             = ["t3.medium"]
    iam_role_attach_cni_policy = true
  }
  eks_managed_node_groups = {
    default_node_group = {
      use_custom_launch_template = false
      instance_types             = ["t3.medium"]
      disk_size                  = 50
      desired_size               = 2
    }
  }
}


resource "aws_security_group_rule" "allow_subnet" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp" # This allows all protocols
  cidr_blocks = ["10.0.0.0/16"]
  security_group_id = module.eks.cluster_primary_security_group_id
}


resource "helm_release" "nginx-ingress-controller" {
  name       = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"


  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

}

