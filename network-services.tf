resource "google_dns_managed_zone" "default" {
  dns_name    = "serenacodes.com."
  name        = "serenacodes-zone"
  description = "dns zone for serenacodes.com"
}

