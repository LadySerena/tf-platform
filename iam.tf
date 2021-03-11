locals {
  cloud_build_account = "serviceAccount:681636924832@cloudbuild.gserviceaccount.com"
}

# give cloud build service account perms for pubsub
module "project-iam-bindings" {
  source = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = [
  data.google_project.project.project_id]
  mode = "additive"

  bindings = {
    "roles/iam.serviceAccountCreator" = [
      local.cloud_build_account,
    ],
    "roles/serviceusage.serviceUsageAdmin" = [
      local.cloud_build_account,
    ],
    "roles/iam.securityAdmin" = [
      local.cloud_build_account,
    ],
    "roles/compute.admin" = [
      local.cloud_build_account,
    ],
    "roles/storage.admin" = [
      local.cloud_build_account,
    ],
    "roles/iam.serviceAccountUser" = [
      local.cloud_build_account,
    ],
    "roles/compute.imageUser" = [
      "serviceAccount:952032963423@cloudbuild.gserviceaccount.com",
    ],
    "roles/dns.admin" = [
      local.cloud_build_account,
    ],
    "roles/cloudfunctions.admin" = [
      local.cloud_build_account,
    ],
    "roles/pubsub.admin" = [
      local.cloud_build_account,
    ],
  }
}

module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = data.google_project.project.project_id
  prefix     = "tel-sa"
  names = [
  "minecraft"]
  project_roles = [
    "${data.google_project.project.project_id}=>roles/secretmanager.viewer",
    "${data.google_project.project.project_id}=>roles/logging.logWriter",
    "${data.google_project.project.project_id}=>roles/monitoring.metricWriter",
    "${data.google_project.project.project_id}=>roles/secretmanager.secretAccessor",
  ]
}

module "discord_notifier_service_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = data.google_project.project.project_id
  prefix     = "tel-sa"
  names = [
  "discord-function"]
  project_roles = [
    "${data.google_project.project.project_id}=>roles/secretmanager.viewer",
    "${data.google_project.project.project_id}=>roles/secretmanager.secretAccessor",
  ]
}
