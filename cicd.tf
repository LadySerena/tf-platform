module "platform-terraform-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//pr-and-tag?ref=0.2.0"
  ownerName = "LadySerena"
  repoName = "tf-platform"
  project_id = data.google_project.project.project_id
  ciMainPath = "ci/apply/cloudbuild.yaml"
  ciDevPath = "ci/plan/cloudbuild.yaml"
}