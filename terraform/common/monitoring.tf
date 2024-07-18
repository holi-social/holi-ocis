resource "google_monitoring_uptime_check_config" "cloud_production" {
  display_name     = "Uptime Monitoring ${local.cloud_production_domain_name}"
  timeout          = "10s"
  period           = "900s"
  selected_regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA"]

  http_check {
    path         = "/"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "holi-shared"
      host       = local.cloud_production_domain_name
    }
  }
}

resource "google_monitoring_uptime_check_config" "cloud_production_wopiserver" {
  display_name     = "Uptime Monitoring ${local.cloud_production_wopiserver_domain_name}"
  timeout          = "10s"
  period           = "900s"
  selected_regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA"]

  http_check {
    path         = "/wopi"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "holi-shared"
      host       = local.cloud_production_wopiserver_domain_name
    }
  }
}

resource "google_monitoring_uptime_check_config" "cloud_production_onlyoffice" {
  display_name     = "Uptime Monitoring ${local.cloud_production_onlyoffice_domain_name}"
  timeout          = "10s"
  period           = "900s"
  selected_regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA"]

  http_check {
    path         = "/welcome"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "holi-shared"
      host       = local.cloud_production_onlyoffice_domain_name
    }
  }
}
