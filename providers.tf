terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
  }
}

# Configuration options
provider "aws" {
  region  = var.my_bucket_region
  profile = "default"
}
