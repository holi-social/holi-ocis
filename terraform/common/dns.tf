# cloud zone (cloud.holi.social)
resource "google_dns_managed_zone" "cloud_zone" {
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name     = "cloud-holi-social-zone"
  dns_name = "cloud.${data.terraform_remote_state.holi_infra_state.outputs.dns_sld_zone_domain}." # cloud.holi.social.
}

resource "google_dns_record_set" "cloud_zone_entry" {
  name = google_dns_managed_zone.cloud_zone.dns_name
  type = "NS"
  ttl  = 300

  managed_zone = data.terraform_remote_state.holi_infra_state.outputs.dns_sld_zone_name

  rrdatas = google_dns_managed_zone.cloud_zone.name_servers
}

locals {
  cloud_development_domain_name            = trim("development.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
  cloud_development_wopiserver_domain_name = trim("development.wopi.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
  cloud_development_onlyoffice_domain_name = trim("development.office.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
  cloud_production_domain_name             = trim("production.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
  cloud_production_wopiserver_domain_name  = trim("production.wopi.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
  cloud_production_onlyoffice_domain_name  = trim("production.office.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
}

# subdomain development.cloud.holi.social
resource "google_dns_record_set" "cloud_development_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_development_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_development_ocis_ip]
}

# subdomain development.wopi.cloud.holi.social
resource "google_dns_record_set" "cloud_development_wopi_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_development_wopiserver_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_development_ocis_ip]
}

# subdomain development.office.cloud.holi.social
resource "google_dns_record_set" "cloud_development_office_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_development_onlyoffice_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_development_ocis_ip]
}

# subdomain production.cloud.holi.social
resource "google_dns_record_set" "cloud_production_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_production_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_production_ocis_ip]
}

# subdomain production.wopi.cloud.holi.social
resource "google_dns_record_set" "cloud_production_wopi_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_production_wopiserver_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_production_ocis_ip]
}

# subdomain production.office.cloud.holi.social
resource "google_dns_record_set" "cloud_production_office_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_production_onlyoffice_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_production_ocis_ip]
}
