
data "google_secret_manager_secret" "ocis_admin_password_development" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_ADMIN_PASSWORD_DEVELOPMENT"
}

data "google_secret_manager_secret" "ocis_admin_password_production" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  secret  = "OCIS_ADMIN_PASSWORD_PRODUCTION"
}

data "template_file" "init_script_prod" {
  template = file("${path.module}/scripts/init-ocis.sh")
  vars = {
    cert_email          = "daniel.bimschas@holi.team"
    ocis_url            = local.cloud_production_domain_name
    ory_url             = "https://auth.project-holi.org"
    ory_client_id       = "4838872a-e1b0-4c59-9913-035db1fa808f"
    ocis_admin_password = data.google_secret_manager_secret_version_access.ocis_admin_password_development.secret_data
  }
}

data "template_file" "init_script_dev" {
  template = file("${path.module}/scripts/init-ocis.sh")
  vars = {
    cert_email          = "daniel.bimschas@holi.team"
    ocis_url            = local.cloud_development_domain_name
    ory_url             = "https://dev-auth.project-holi.org"
    ory_client_id       = "b1c892b2-3746-4fca-a3f7-b3bafcffd9ee"
    ocis_admin_password = data.google_secret_manager_secret_version_access.ocis_admin_password_production.secret_data
  }
}

resource "google_compute_instance" "development_ocis" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "cloud-development-ocis"
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

  metadata {
    # used instead of metadata_startup_script which forces the VM to be recreated upon changes of contents
    # this startup-script is executed on every reboot
    startup-script = data.template_file.init_script_dev.rendered
  }

  service_account {
    email  = local.cloud_service_account_email
    scopes = ["compute-rw"]
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

  metadata_startup_script = data.template_file.init_script_prod.rendered

  service_account {
    email  = local.cloud_service_account_email
    scopes = ["compute-rw"]
  }

  tags = ["http-server", "https-server"]
}

locals {
  cloud_development_ocis_ip = google_compute_instance.development_ocis.network_interface.0.access_config.0.nat_ip
  cloud_production_ocis_ip  = google_compute_instance.production_ocis.network_interface.0.access_config.0.nat_ip
}
