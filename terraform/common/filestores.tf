resource "google_filestore_instance" "ocis_development" {
  name     = "ocis-development"
  location = "europe-north1-a" # finland, low CO2 emissions
  tier     = "BASIC_HDD"       # standard tier
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id

  file_shares {
    capacity_gb = 1024 # minimum value for standard tier
    name        = "ocis_data"
    # TODO(SF) source_backup
    
    nfs_export_options {
      ip_ranges = [data.terraform_remote_state.holi_infra_state.outputs.vpc_access_connector_ip_cidr_range]
      access_mode = "READ_WRITE"
      squash_mode = "NO_ROOT_SQUASH"
   }
  }

  networks {
    # TODO(SF) ??
    network = data.terraform_remote_state.holi_infra_state.outputs.vpc_access_connector_name # = "default"
    modes   = ["MODE_IPV4"]
    # TODO(SF) used by redis
    # connect_mode       = "PRIVATE_SERVICE_ACCESS"
  }
}

resource "google_filestore_instance" "ocis_production" {
  name     = "ocis-production"
  location = "europe-north1-a" # finland, low CO2 emissions
  tier     = "BASIC_HDD"       # standard tier
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id

  file_shares {
    capacity_gb = 1024 # minimum value for standard tier
    name        = "ocis_data"
    # TODO(SF) source_backup

    nfs_export_options {
      ip_ranges = [data.terraform_remote_state.holi_infra_state.outputs.vpc_access_connector_ip_cidr_range]
      access_mode = "READ_WRITE"
      squash_mode = "NO_ROOT_SQUASH"
   }
  }

  networks {
    # TODO(SF) ??
    network = data.terraform_remote_state.holi_infra_state.outputs.vpc_access_connector_name # = "default"
    modes   = ["MODE_IPV4"]
    # TODO(SF) used by redis
    # connect_mode       = "PRIVATE_SERVICE_ACCESS"
  }
}

output "ocis_filestore_development_ip" {
  value = google_filestore_instance.ocis_development.networks.0.ip_addresses.0
}

output "ocis_filestore_development_fileshare_name" {
  value = google_filestore_instance.ocis_development.file_shares.0.name
}

output "ocis_filestore_production_ip" {
  value = google_filestore_instance.ocis_production.networks.0.ip_addresses.0
}

output "ocis_filestore_production_fileshare_name" {
  value = google_filestore_instance.ocis_production.file_shares.0.name
}
