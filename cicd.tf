module "platform-terraform-triggers" {
  source            = "git::https://github.com/LadySerena/terraform-modules.git//github-push-pr-tag-triggers?ref=1.0.0"
  ownerName         = "LadySerena"
  repoName          = "tf-platform"
  project_id        = data.google_project.project.project_id
  ciBranchPushPath  = "ci/plan/cloudbuild.yaml"
  ciTagPath         = "ci/apply/cloudbuild.yaml"
  ciPullRequestPath = "ci/plan/cloudbuild.yaml"
}

module "base-image-triggers" {
  source     = "git::https://github.com/LadySerena/terraform-modules.git//pr-and-tag?ref=0.2.0"
  ownerName  = "LadySerena"
  repoName   = "gce-base-image"
  project_id = data.google_project.project.project_id
  ciMainPath = "ci/release/cloudbuild.yaml"
  ciDevPath  = "ci/feature/cloudbuild.yaml"
}

module "discord-notifier-trigger" {
  source            = "git::https://github.com/LadySerena/terraform-modules.git//github-push-pr-tag-triggers?ref=1.0.0"
  ownerName         = "LadySerena"
  project_id        = data.google_project.project.project_id
  repoName          = "discord-notification-function"
  ciBranchPushPath  = "ci/branch-push/cloudbuild.yaml"
  ciTagPath         = "ci/release/cloudbuild.yaml"
  ciPullRequestPath = "ci/branch-push/cloudbuild.yaml"
}

module "rpi-image-triggers" {
  source            = "git::https://github.com/LadySerena/terraform-modules.git//github-push-pr-tag-triggers?ref=1.0.0"
  ownerName         = "LadySerena"
  project_id        = data.google_project.project.project_id
  repoName          = "rpi-image-builder-gce"
  ciBranchPushPath  = "ci/feature/cloudbuild.yaml"
  ciTagPath         = "ci/release/cloudbuild.yaml"
  ciPullRequestPath = "ci/feature/cloudbuild.yaml"
}

