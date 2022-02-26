resource "google_storage_bucket" "pi-images" {
  name                        = "pi-images.serenacodes.com"
  location                    = "US"
  project                     = data.google_project.project.project_id
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "pi-keys" {
  name                        = "pi-pub-keys.serenacodes.com"
  location                    = "US"
  project                     = data.google_project.project.project_id
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "pi-image-sa-member" {
  bucket = google_storage_bucket.pi-images.name
  role   = "roles/storage.objectAdmin"
  member = module.pi_image_service_account.iam_email
}

resource "google_storage_bucket_iam_member" "serena-pi-images" {
  bucket = google_storage_bucket.pi-images.name
  role   = "roles/storage.objectAdmin"
  member = "user:serena.tiede@gmail.com"
}

resource "google_storage_bucket_iam_member" "serena-pi-keys" {
  bucket = google_storage_bucket.pi-keys.name
  role   = "roles/storage.objectAdmin"
  member = "user:serena.tiede@gmail.com"
}
