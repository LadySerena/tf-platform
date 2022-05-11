resource "google_storage_bucket" "pi-images" {
  name                        = "pi-images.serenacodes.com"
  location                    = "US"
  project                     = data.google_project.project.project_id
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "pi-keys" {
  name                        = "pi-host-keys.serenacodes.com"
  location                    = "US"
  project                     = data.google_project.project.project_id
  uniform_bucket_level_access = true
  force_destroy               = true
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

resource "google_storage_bucket_iam_member" "serena-containers" {
  bucket = google_container_registry.home-lab-registry.id
  role   = "roles/storage.objectAdmin"
  member = "user:serena.tiede@gmail.com"
}

resource "google_storage_bucket_iam_member" "containers-sa-member" {
  bucket = google_container_registry.home-lab-registry.id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.image-puller-account.email}"
}