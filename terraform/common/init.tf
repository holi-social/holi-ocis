terraform {
  # allow the lowest common version across all projects, so that the current CI docker image version suits all projects
  required_version = ">= 1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.22.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.22.0"
    }
  }
  backend "gcs" {
    bucket = "holi-shared-terraform-state"
    prefix = "owncloud-api-common"
  }
}

data "terraform_remote_state" "holi_infra_state" {
  backend = "gcs"
  config = {
    bucket = "holi-shared-terraform-state"
    prefix = "infra"
  }
}

data "terraform_remote_state" "holi_infra_monitoring_state" {
  backend = "gcs"
  config = {
    bucket = "holi-shared-terraform-state"
    prefix = "infra-monitoring"
  }
}

# provider google including beta features
provider "google" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  region  = local.default_region
}

provider "google-beta" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  region  = local.default_region
}
