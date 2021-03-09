data "google_project" "project" {
}

module "project-services" {
  source      = "terraform-google-modules/project-factory/google//modules/project_services"
  version     = "10.2.0"
  enable_apis = true
  project_id  = data.google_project.project.project_id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudfunctions.googleapis.com"
  ]
}