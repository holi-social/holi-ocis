data "google_secret_manager_secret_version_access" "ocis_admin_password_development" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_ADMIN_PASSWORD_DEVELOPMENT"
}

data "google_secret_manager_secret_version_access" "ocis_admin_password_production" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_ADMIN_PASSWORD_PRODUCTION"
}

data "google_secret_manager_secret_version_access" "ory_client_id_development" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "ORY_CLIENT_ID_DEVELOPMENT"
}

data "google_secret_manager_secret_version_access" "ory_client_id_production" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "ORY_CLIENT_ID_PRODUCTION"
}

resource "google_storage_bucket" "development_ocis" {
  project       = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name          = "cloud-development-ocis"
  location      = "EUROPE-NORTH1"
  storage_class = "REGIONAL"

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "production_ocis" {
  project       = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name          = "cloud-production-ocis"
  location      = "EUROPE-NORTH1"
  storage_class = "REGIONAL"

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_compute_instance" "development_ocis" {
  project                   = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name                      = "cloud-development-ocis"
  machine_type              = "e2-micro"
  zone                      = "europe-north1-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    # used instead of metadata_startup_script which forces the VM to be recreated upon changes of contents
    # this startup-script is executed on every reboot
    startup-script = templatefile(
      "${path.module}/scripts/init-ocis.sh",
      {
        cert_email            = "daniel.bimschas@holi.team"
        ocis_url              = local.cloud_development_domain_name
        ory_url               = "https://dev-auth.holi.social"
        ory_client_id         = data.google_secret_manager_secret_version_access.ory_client_id_development.secret_data
        ocis_admin_password   = data.google_secret_manager_secret_version_access.ocis_admin_password_development.secret_data
        storage_access_id     = local.cloud_storage_access_key_development.access_id
        storage_access_secret = local.cloud_storage_access_key_development.secret
        storage_bucket        = local.storage_development_bucket
      }
    )
  }

  service_account {
    email = local.cloud_service_account_email
    scopes = [
      # More fine grained access defined using IAM roles
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  tags = ["http-server", "https-server"]
}

resource "google_compute_instance" "production_ocis" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "cloud-production-ocis"
  machine_type = "e2-micro"
  zone         = "europe-north1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    # used instead of metadata_startup_script which forces the VM to be recreated upon changes of contents
    # this startup-script is executed on every reboot
    startup-script = templatefile(
      "${path.module}/scripts/init-ocis.sh",
      {
        cert_email            = "daniel.bimschas@holi.team"
        ocis_url              = local.cloud_production_domain_name
        ory_url               = "https://auth.holi.social"
        ory_client_id         = data.google_secret_manager_secret_version_access.ory_client_id_production.secret_data
        ocis_admin_password   = data.google_secret_manager_secret_version_access.ocis_admin_password_production.secret_data
        storage_access_id     = local.cloud_storage_access_key_production.access_id
        storage_access_secret = local.cloud_storage_access_key_production.secret
        storage_bucket        = local.storage_production_bucket
      }
    )
  }

  service_account {
    email = local.cloud_service_account_email
    scopes = [
      # More fine grained access defined using IAM roles
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  tags = ["http-server", "https-server"]
}

locals {
  cloud_development_ocis_ip  = google_compute_instance.development_ocis.network_interface.0.access_config.0.nat_ip
  cloud_production_ocis_ip   = google_compute_instance.production_ocis.network_interface.0.access_config.0.nat_ip
  storage_development_bucket = google_storage_bucket.development_ocis.name
  storage_production_bucket  = google_storage_bucket.production_ocis.name
}
