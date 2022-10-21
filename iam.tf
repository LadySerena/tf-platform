locals {
  cloud_build_account    = "serviceAccount:681636924832@cloudbuild.gserviceaccount.com"
  service_account_prefix = "tel-sa"
}

# give cloud build service account perms for pubsub
module "project-iam-bindings" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = [
    data.google_project.project.project_id
  ]
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
    "roles/dns.admin" = [
      local.cloud_build_account,
    ],
    "roles/cloudfunctions.admin" = [
      local.cloud_build_account,
    ],
    "roles/pubsub.admin" = [
      local.cloud_build_account,
    ],
    "roles/iam.serviceAccountAdmin" = [
      local.cloud_build_account
    ],
    "roles/iam.workloadIdentityPoolAdmin" = [
      local.cloud_build_account
    ]
  }
}

module "discord_notifier_service_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = data.google_project.project.project_id
  prefix     = local.service_account_prefix
  names      = [
    "discord-function"
  ]
  project_roles = [
    "${data.google_project.project.project_id}=>roles/secretmanager.secretAccessor",
  ]
}

module "pi_image_service_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = data.google_project.project.project_id
  prefix     = local.service_account_prefix
  names      = [
    "pi-image-builder"
  ]
  project_roles = [
    "${data.google_project.project.project_id}=>roles/secretmanager.secretAccessor",
    "${data.google_project.project.project_id}=>roles/monitoring.metricWriter",
    "${data.google_project.project.project_id}=>roles/logging.logWriter",
    "${data.google_project.project.project_id}=>roles/compute.instanceAdmin.v1"
  ]
}


module "dns01-challenge-account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = data.google_project.project.project_id
  prefix     = local.service_account_prefix
  names      = [
    "dns01-challenge"
  ]
  project_roles = [
    "${data.google_project.project.project_id}=>roles/dns.admin",
  ]
}

module "kubernetes_bootstrap_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = data.google_project.project.project_id
  prefix     = local.service_account_prefix
  names      = [
    "kube-secret-viewer"
  ]
  project_roles = [
    "${data.google_project.project.project_id}=>roles/secretmanager.secretAccessor",
  ]
}

resource "google_service_account" "image-puller-account" {
  account_id   = "tel-sa-home-lab-image-pull"
  display_name = "homelab-image-puller"
}

resource "google_service_account" "github-actions-image-push" {
  account_id   = "tel-sa-home-lab-image-push"
  display_name = "github-actions-image-push"
}

module "gh_oidc" {
  source      = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  project_id  = data.google_project.project.project_id
  pool_id     = "github-actions-pool"
  provider_id = "github-provider"
  sa_mapping  = {
    (google_service_account.github-actions-image-push.account_id) = {
      sa_name   = google_service_account.github-actions-image-push.name
      attribute = "attribute.repository/LadySerena/basic-web"
    }
  }
}
