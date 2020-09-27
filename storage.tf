resource "google_storage_bucket" "debian-v1" {
  name = "debian-v1.platform.serenacodes.com"
  location = "US"
  project = data.google_project.project.id
  storage_class = "STANDARD"
  uniform_bucket_level_access = true
}