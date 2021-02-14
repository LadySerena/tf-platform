module "platform-terraform-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//github-push-pr-tag-triggers?ref=1.0.0"
  ownerName = "LadySerena"
  repoName = "tf-platform"
  project_id = data.google_project.project.project_id
  ciBranchPushPath = "ci/plan/cloudbuild.yaml"
  ciTagPath = "ci/apply/cloudbuild.yaml"
  ciPullRequestPath = "ci/plan/cloudbuild.yaml"
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

module "dbus-api-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//github-push-pr-tag-triggers?ref=1.0.0"
  ownerName = "LadySerena"
  project_id = data.google_project.project.project_id
  repoName = "dbus-api"
}

module "paper-debian-package-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//github-push-pr-tag-triggers?ref=1.0.0"
  ownerName = "LadySerena"
  project_id = data.google_project.project.project_id
  repoName = "paper-debian-package"
  ciBranchPushPath = "ci/branch-push/cloudbuild.yaml"
  ciTagPath = "ci/release/cloudbuild.yaml"
  ciPullRequestPath = "ci/pull-request/cloudbuild.yaml"
}

module "paper-image-triggers" {
  source = "git::https://github.com/LadySerena/terraform-modules.git//github-push-pr-tag-triggers?ref=1.0.0"
  ownerName = "LadySerena"
  project_id = data.google_project.project.project_id
  repoName = "paper-image"
  ciBranchPushPath = "ci/branch-push/cloudbuild.yaml"
  ciTagPath = "ci/release/cloudbuild.yaml"
  ciPullRequestPath = "ci/pull-request/cloudbuild.yaml"
}
