## these dns changes are done in the infra shared project (https://gitlab.com/holisticfoundation/holi-infra)
## because the zone apis.project-holi.org is managed in that project.

# TODO (DB) (SF) eigene DNS zone ({staging|production|...}.cloud.project-holi.org ?)

locals {
  # effectively, this is owncloud.apis.project-holi.org
  owncloud_api_environments_zone_dns_name = "owncloud.${data.terraform_remote_state.holi_infra_state.outputs.dns_apis_zone_domain}."
}

# owncloud api environments zone
resource "google_dns_managed_zone" "owncloud_api_environments_zone" {
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name     = "owncloud-api-environments-zone"
  dns_name = local.owncloud_api_environments_zone_dns_name
}

resource "google_dns_record_set" "owncloud_api_environments_zone_entry" {
  project = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  name    = local.owncloud_api_environments_zone_dns_name
  type    = "NS"
  ttl     = 300

  managed_zone = data.terraform_remote_state.holi_infra_state.outputs.dns_apis_zone_name

  rrdatas = google_dns_managed_zone.owncloud_api_environments_zone.name_servers
}

output "dns_owncloud_api_domain" {
  value = trim(google_dns_managed_zone.owncloud_api_environments_zone.dns_name, ".")
}

output "dns_owncloud_api_domain_name" {
  value = google_dns_managed_zone.owncloud_api_environments_zone.name
}
