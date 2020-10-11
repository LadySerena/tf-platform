module "serenacodes-public-zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "3.0.0"
  project_id = data.google_project.project.project_id
  type       = "public"
  name       = "serenacodes"
  domain     = "serenacodes.com."
}
