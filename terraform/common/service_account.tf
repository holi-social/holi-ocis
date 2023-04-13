resource "google_service_account" "cloud" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  account_id   = "holi-cloud"
  display_name = "cloud service account for OCIS"
}

resource "google_project_iam_member" "cloud" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/storage.objectAdmin"
  ])
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  member  = "serviceAccount:${google_service_account.cloud.email}"
  role    = each.key
}

resource "google_storage_hmac_key" "cloud_storage_access_key_development" {
  project               = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  service_account_email = google_service_account.cloud.email
}

resource "google_storage_hmac_key" "cloud_storage_access_key_production" {
  project               = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  service_account_email = google_service_account.cloud.email
}

locals {
  cloud_service_account_email          = google_service_account.cloud.email
  cloud_storage_access_key_development = google_storage_hmac_key.cloud_storage_access_key_development
  cloud_storage_access_key_production  = google_storage_hmac_key.cloud_storage_access_key_production
}

