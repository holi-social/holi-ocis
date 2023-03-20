# cloud zone (cloud.project-holi.org)
resource "google_dns_managed_zone" "cloud_zone" {
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name     = "cloud-zone"
  dns_name = "cloud.${data.terraform_remote_state.holi_infra_state.outputs.dns_sld_zone_domain}." # cloud.project-holi.org.
}

resource "google_dns_record_set" "cloud_zone_entry" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name    = google_dns_managed_zone.cloud_zone.dns_name
  type    = "NS"
  ttl     = 300

  managed_zone = data.terraform_remote_state.holi_infra_state.outputs.dns_sld_zone_name

  rrdatas = google_dns_managed_zone.cloud_zone.name_servers
}

locals {
  cloud_development_domain_name = trim("development.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
  cloud_production_domain_name  = trim("production.${google_dns_managed_zone.cloud_zone.dns_name}", ".")
}

# subdomain dev.cloud.project-holi.org
resource "google_dns_record_set" "cloud_development_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_development_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_development_ocis_ip]
}

# subdomain prod.cloud.project-holi.org
resource "google_dns_record_set" "cloud_production_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.cloud_production_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.cloud_zone.name
  rrdatas      = [local.cloud_production_ocis_ip]
}

