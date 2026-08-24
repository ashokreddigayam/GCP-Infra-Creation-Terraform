terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = file("/tmp/Vulnerabilities/Infrastructure/supple-apricot-504106-m6-3e44cc1b3143.json")
}
