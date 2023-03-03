## these dns changes are done in the infra shared project (https://gitlab.com/holisticfoundation/holi-infra)
## because the zone apis.project-holi.org is managed in that project.

locals {
  # effectively, this is ocis.apis.project-holi.org
  ocis_api_environments_zone_dns_name = "ocis.${data.terraform_remote_state.holi_infra_state.outputs.dns_apis_zone_domain}."
}

# ocis api environments zone
resource "google_dns_managed_zone" "ocis_api_environments_zone" {
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name     = "ocis-api-environments-zone"
  dns_name = local.ocis_api_environments_zone_dns_name
}

resource "google_dns_record_set" "ocis_api_environments_zone_entry" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name    = local.ocis_api_environments_zone_dns_name
  type    = "NS"
  ttl     = 300

  managed_zone = data.terraform_remote_state.holi_infra_state.outputs.dns_apis_zone_name

  rrdatas = google_dns_managed_zone.ocis_api_environments_zone.name_servers
}

output "dns_ocis_api_domain" {
  value = trim(google_dns_managed_zone.ocis_api_environments_zone.dns_name, ".")
}

output "dns_ocis_api_domain_name" {
  value = google_dns_managed_zone.ocis_api_environments_zone.name
}
