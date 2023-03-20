resource "google_service_account" "owncloud_api" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  account_id   = "cloudrun-service-owncloud"
  display_name = "owncloud API service account for Cloud Run"
}

resource "google_project_iam_member" "owncloud_api" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  member  = "serviceAccount:${google_service_account.owncloud_api.email}"
  role    = "roles/secretmanager.secretAccessor"
}

output "cloud_run_service_account_email" {
  value = google_service_account.owncloud_api.email
}

resource "google_service_account" "cloud" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  account_id   = "holi-cloud"
  display_name = "cloud service account for OCIS"
}

locals {
  cloud_service_account_email = google_service_account.cloud.email
}
