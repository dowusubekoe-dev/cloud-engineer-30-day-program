terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "derek-lab-tfstate"
    key            = "week1/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "derek-lab-tflock"
    encrypt        = true
    profile        = "terraform"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform"
}

module "network" {
  source = "./modules/network"
}

module "compute" {
  source                   = "./modules/compute"
  vpc_id                   = module.network.vpc_id
  public_subnet_ids        = module.network.public_subnet_ids
  app_subnet_ids           = module.network.app_subnet_ids
  public_security_group_id = module.network.public_security_group_id
  app_security_group_id    = module.network.app_security_group_id
}

module "data" {
  source                 = "./modules/data"
  data_subnet_ids        = module.network.data_subnet_ids
  data_security_group_id = module.network.data_security_group_id
}
