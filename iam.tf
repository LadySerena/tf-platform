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
    ],
    "roles/compute.admin" = [
      "serviceAccount:681636924832@cloudbuild.gserviceaccount.com",
    ],
    "roles/storage.admin" = [
      "serviceAccount:681636924832@cloudbuild.gserviceaccount.com",
    ],
    "roles/iam.serviceAccountUser" = [
      "serviceAccount:681636924832@cloudbuild.gserviceaccount.com",
    ],
    "roles/compute.imageUser" = [
      "serviceAccount:952032963423@cloudbuild.gserviceaccount.com",
      "serviceAccount:1059113020718@cloudbuild.gserviceaccount.com",
    ],
  }
}
