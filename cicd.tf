module "platform-terraform-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//pr-and-tag?ref=0.2.0"
  ownerName = "LadySerena"
  repoName = "tf-platform"
  project_id = data.google_project.project.project_id
  ciMainPath = "ci/apply/cloudbuild.yaml"
  ciDevPath = "ci/plan/cloudbuild.yaml"
}

module "base-image-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//pr-and-tag?ref=0.2.0"
  ownerName = "LadySerena"
  repoName = "gce-base-image"
  project_id = data.google_project.project.project_id
  ciMainPath = "ci/release/cloudbuild.yaml"
  ciDevPath = "ci/feature/cloudbuild.yaml"
}

module "node-exporter-deb-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//pr-and-tag?ref=0.2.0"
  ownerName = "LadySerena"
  repoName = "node-exporter-deb"
  project_id = data.google_project.project.project_id
  ciMainPath = "ci/release/cloudbuild.yaml"
  ciDevPath = "ci/feature/cloudbuild.yaml"
}
