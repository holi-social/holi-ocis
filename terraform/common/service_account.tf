resource "google_service_account" "cloud" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  account_id   = "holi-cloud"
  display_name = "cloud service account for OCIS"
}

resource "google_project_iam_member" "cloud" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  member  = "serviceAccount:${google_service_account.cloud.email}"
  role    = each.key
}

locals {
  cloud_service_account_email = google_service_account.cloud.email
}

