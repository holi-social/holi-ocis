# Development database configuratrion
data "google_secret_manager_secret_version_access" "onlyoffice_db_password_development" {
  secret = "ONLYOFFICE_DB_PASSWORD_DEVELOPMENT"
}

resource "google_sql_user" "onlyoffice_db_user_development" {
  name     = "onlyoffice"
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  instance = data.terraform_remote_state.holi_infra_state.outputs.database_name_development
  password = data.google_secret_manager_secret_version_access.onlyoffice_db_password_development.secret_data
}

resource "google_sql_database" "onlyoffice_db_development" {
  name     = "onlyoffice-development"
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  instance = data.terraform_remote_state.holi_infra_state.outputs.database_name_development
}

# Production database configuratrion
data "google_secret_manager_secret_version_access" "onlyoffice_db_password_production" {
  secret = "ONLYOFFICE_DB_PASSWORD_PRODUCTION"
}

resource "google_sql_user" "onlyoffice_db_user_production" {
  name     = "onlyoffice"
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  instance = data.terraform_remote_state.holi_infra_state.outputs.database_name_production
  password = data.google_secret_manager_secret_version_access.onlyoffice_db_password_production.secret_data
}

resource "google_sql_database" "onlyoffice_db_production" {
  name     = "onlyoffice-production"
  project  = data.terraform_remote_state.holi_infra_state.outputs.shared_project_id
  instance = data.terraform_remote_state.holi_infra_state.outputs.database_name_production
}
