resource "google_service_account" "cloud" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  account_id   = "holi-cloud"
  display_name = "cloud service account for OCIS"
}

locals {
  cloud_service_account_email = google_service_account.cloud.email
}
