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

data "google_secret_manager_secret_version_access" "ocis_jwt_secret_development" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_JWT_SECRET_DEVELOPMENT"
}

data "google_secret_manager_secret_version_access" "wopisecret_development" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_WOPISECRET_DEVELOPMENT"
}

data "google_secret_manager_secret_version_access" "iopsecret_development" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_IOPSECRET_DEVELOPMENT"
}

data "google_secret_manager_secret_version_access" "onlyoffice_jwt_secret_development" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "ONLYOFFICE_JWT_SECRET_DEVELOPMENT"
}

data "google_secret_manager_secret_version_access" "ocis_jwt_secret_production" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_JWT_SECRET_PRODUCTION"
}

data "google_secret_manager_secret_version_access" "wopisecret_production" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_WOPISECRET_PRODUCTION"
}

data "google_secret_manager_secret_version_access" "iopsecret_production" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_IOPSECRET_PRODUCTION"
}

data "google_secret_manager_secret_version_access" "onlyoffice_jwt_secret_production" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "ONLYOFFICE_JWT_SECRET_PRODUCTION"
}

# START encrypted storage buckets
data "google_storage_project_service_account" "gcs_account" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
}

# dev

resource "google_kms_crypto_key" "ocis_development_bucket_key" {
  name     = "ocis-development-bucket-key"
  key_ring = data.terraform_remote_state.holi_infra_state.outputs.kms_shared_key_ring_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "ocis_development_bucket_key_binding" {
  crypto_key_id = google_kms_crypto_key.ocis_development_bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
  ]
}

resource "google_storage_bucket" "development_ocis" {
  project       = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name          = "cloud-development-ocis"
  location      = local.default_region
  storage_class = "REGIONAL"

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.ocis_development_bucket_key.id
  }

  depends_on = [google_kms_crypto_key_iam_binding.ocis_development_bucket_key_binding]
}

# production

resource "google_kms_crypto_key" "ocis_production_bucket_key" {
  name     = "ocis-production-bucket-key"
  key_ring = data.terraform_remote_state.holi_infra_state.outputs.kms_shared_key_ring_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "ocis_production_bucket_key_binding" {
  crypto_key_id = google_kms_crypto_key.ocis_production_bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
  ]
}

resource "google_storage_bucket" "production_ocis" {
  project       = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name          = "cloud-production-ocis"
  location      = local.default_region
  storage_class = "REGIONAL"

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.ocis_development_bucket_key.id
  }

  depends_on = [google_kms_crypto_key_iam_binding.ocis_production_bucket_key_binding]
}
# END encrypted storage buckets


resource "google_compute_instance" "development_ocis" {
  project                   = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name                      = "cloud-development-ocis"
  machine_type              = "e2-standard-2"
  zone                      = "${local.default_region}-a"
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
        cert_email             = "daniel.bimschas@holi.team"
        ocis_url               = local.cloud_development_domain_name
        ory_url                = "https://dev-auth.holi.social"
        ory_client_id          = data.google_secret_manager_secret_version_access.ory_client_id_development.secret_data
        ocis_admin_password    = data.google_secret_manager_secret_version_access.ocis_admin_password_development.secret_data
        storage_access_id      = local.cloud_storage_access_key_development.access_id
        storage_access_secret  = local.cloud_storage_access_key_development.secret
        storage_bucket         = local.storage_development_bucket
        ocis_jwt_secret        = data.google_secret_manager_secret_version_access.ocis_jwt_secret_development.secret_data
        wopiserver_url         = local.cloud_development_wopiserver_domain_name
        iopsecret              = data.google_secret_manager_secret_version_access.iopsecret_development.secret_data
        wopisecret             = data.google_secret_manager_secret_version_access.wopisecret_development.secret_data
        onlyoffice_url         = local.cloud_development_onlyoffice_domain_name
        onlyoffice_db_host     = data.terraform_remote_state.holi_infra_state.outputs.database_ip_address_development
        onlyoffice_db_name     = google_sql_database.onlyoffice_db_development.name
        onlyoffice_db_user     = google_sql_user.onlyoffice_db_user_development.name
        onlyoffice_db_password = google_sql_user.onlyoffice_db_user_development.password
        onlyoffice_jwt_secret  = data.google_secret_manager_secret_version_access.onlyoffice_jwt_secret_development.secret_data
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
  project                   = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name                      = "cloud-production-ocis"
  machine_type              = "e2-standard-2"
  zone                      = "${local.default_region}-a"
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
        cert_email             = "daniel.bimschas@holi.team"
        ocis_url               = local.cloud_production_domain_name
        ory_url                = "https://auth.holi.social"
        ory_client_id          = data.google_secret_manager_secret_version_access.ory_client_id_production.secret_data
        ocis_admin_password    = data.google_secret_manager_secret_version_access.ocis_admin_password_production.secret_data
        storage_access_id      = local.cloud_storage_access_key_production.access_id
        storage_access_secret  = local.cloud_storage_access_key_production.secret
        storage_bucket         = local.storage_production_bucket
        ocis_jwt_secret        = data.google_secret_manager_secret_version_access.ocis_jwt_secret_production.secret_data
        wopiserver_url         = local.cloud_production_wopiserver_domain_name
        iopsecret              = data.google_secret_manager_secret_version_access.iopsecret_production.secret_data
        wopisecret             = data.google_secret_manager_secret_version_access.wopisecret_production.secret_data
        onlyoffice_url         = local.cloud_production_onlyoffice_domain_name
        onlyoffice_db_host     = data.terraform_remote_state.holi_infra_state.outputs.database_ip_address_production
        onlyoffice_db_name     = google_sql_database.onlyoffice_db_production.name
        onlyoffice_db_user     = google_sql_user.onlyoffice_db_user_production.name
        onlyoffice_db_password = google_sql_user.onlyoffice_db_user_production.password
        onlyoffice_jwt_secret  = data.google_secret_manager_secret_version_access.onlyoffice_jwt_secret_production.secret_data
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
