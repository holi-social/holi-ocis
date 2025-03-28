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

resource "google_monitoring_alert_policy" "ocis_disk_utilization_production" {
  display_name = "COMO: OCIS disk utilization (production)"
  notification_channels = [
    data.terraform_remote_state.holi_infra_monitoring_state.outputs.monitoring_notification_channel_rocket_chat_production_id,
    data.terraform_remote_state.holi_infra_monitoring_state.outputs.monitoring_notification_channel_slack_production_id,
  ]
  severity = "WARNING"
  alert_strategy {
    auto_close = "86400s" # 1 day
  }
  combiner = "OR"
  conditions {
    display_name = "OCIS disk utilization (production)"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter = templatefile("./monitoring_ocis_disk_utilization.tftpl", {
        instance_id = google_compute_instance.production_ocis.instance_id
      })
      threshold_value = 80

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
      trigger {
        count   = 1
        percent = 0
      }
    }
  }
  documentation {
    content   = "OCIS disk utilization exceeded (production)"
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "ocis_disk_utilization_development" {
  display_name = "COMO: OCIS disk utilization (development)"
  notification_channels = [
    data.terraform_remote_state.holi_infra_monitoring_state.outputs.monitoring_notification_channel_rocket_chat_staging_id,
    data.terraform_remote_state.holi_infra_monitoring_state.outputs.monitoring_notification_channel_slack_staging_id,
  ]
  severity = "WARNING"
  alert_strategy {
    auto_close = "86400s" # 1 day
  }
  combiner = "OR"
  conditions {
    display_name = "OCIS disk utilization (development)"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter = templatefile("./monitoring_ocis_disk_utilization.tftpl", {
        instance_id = google_compute_instance.development_ocis.instance_id
      })
      threshold_value = 80

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
      trigger {
        count   = 1
        percent = 0
      }
    }
  }
  documentation {
    content   = "OCIS disk utilization exceeded (development)"
    mime_type = "text/markdown"
  }
}
