terraform {
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

# provider google including beta features
provider "google" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  region  = local.default_region
}

provider "google-beta" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  region  = local.default_region
}
