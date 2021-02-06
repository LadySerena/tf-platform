resource "google_storage_bucket" "debian-v1" {
  name = "debian-v1.platform.serenacodes.com"
  location = "US"
  project = data.google_project.project.project_id
  storage_class = "STANDARD"
  uniform_bucket_level_access = true
}



module "minecraft-backup" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> v1.7.2"

  name       = "minecraft-world-backups.serenacodes.com"
  project_id = data.google_project.project.project_id
  location   = "us-central1"
  iam_members = [
    {
      role   = "roles/storage.viewer"
      member = "${module.service_accounts.iam_email}"
    },
    {
      role   = "roles/storage.objectCreator"
      member = "${module.service_accounts.iam_email}"
    },
  ]
}

