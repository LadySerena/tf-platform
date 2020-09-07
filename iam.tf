module "project-iam-bindings" {
  source = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = [
    data.google_project.project.project_id]
  mode = "additive"

  bindings = {
    "roles/serviceusage.serviceUsageAdmin" = [
      "serviceAccount:681636924832@cloudbuild.gserviceaccount.com",
    ],
    "roles/iam.securityAdmin" = [
      "serviceAccount:681636924832@cloudbuild.gserviceaccount.com",
    ]
  }
}
