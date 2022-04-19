terraform {
  required_version = ">= 1.0.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.2"
    }
  }
}
