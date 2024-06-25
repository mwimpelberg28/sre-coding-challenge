module "testecr" {
  source  = "terraform-module/ecr/aws"
  version = "~> 1.0"
  ecrs = {
    flasapp = {
      tags = { app = "flaskapp" }
    }
  }
}