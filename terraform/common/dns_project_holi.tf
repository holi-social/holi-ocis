# cloud zone (cloud.project-holi.org)
resource "google_dns_managed_zone" "project_holi_cloud_zone" {
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name     = "cloud-zone"
  dns_name = "cloud.${data.terraform_remote_state.holi_infra_state.outputs.dns_project_holi_sld_zone_domain}." # cloud.project-holi.org.
}

resource "google_dns_record_set" "project_holi_cloud_zone_entry" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name    = google_dns_managed_zone.project_holi_cloud_zone.dns_name
  type    = "NS"
  ttl     = 300

  managed_zone = data.terraform_remote_state.holi_infra_state.outputs.dns_project_holi_sld_zone_name

  rrdatas = google_dns_managed_zone.project_holi_cloud_zone.name_servers
}

locals {
  project_holi_cloud_development_domain_name = trim("development.${google_dns_managed_zone.project_holi_cloud_zone.dns_name}", ".")
  project_holi_cloud_production_domain_name  = trim("production.${google_dns_managed_zone.project_holi_cloud_zone.dns_name}", ".")
}

# subdomain dev.cloud.project-holi.org
resource "google_dns_record_set" "project_holi_cloud_development_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.project_holi_cloud_development_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.project_holi_cloud_zone.name
  rrdatas      = [local.cloud_development_ocis_ip]
}

# subdomain prod.cloud.project-holi.org
resource "google_dns_record_set" "project_holi_cloud_production_entry" {
  project      = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name         = "${local.project_holi_cloud_production_domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.project_holi_cloud_zone.name
  # this IP is pointing to the nginx-proxy, so that we can do a permanent redirect there, fixing the
  # cloud integration for old apps (1.0.14, 1.0.15) that are still using project-holi.org hardcoded.
  # Starting with 1.0.16, the apps should go to the new domain anyways. Don't remove this until we're
  # sure there is no old app versions installed.
  rrdatas = ["35.228.129.14"]
}

