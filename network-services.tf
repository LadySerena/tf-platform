resource "google_dns_managed_zone" "default" {
  dns_name    = "serenacodes.com."
  name        = "serenacodes-zone"
  description = "dns zone for serenacodes.com"
}

resource "google_dns_record_set" "verification" {
  managed_zone = google_dns_managed_zone.default.name
  name = "verification-record"
  rrdatas = ["google-site-verification=QGC_RBY5dkopavcMI_4ZFDloF5y3qVYp_o1dmch9zh0"]
  ttl = 300
  type = "TXT"
}

resource "google_dns_record_set" "blog" {
  managed_zone = google_dns_managed_zone.default.name
  name         = "blog.${google_dns_managed_zone.default.dns_name}"
  rrdatas = [
  "ladyserena.github.io."]
  ttl  = 300
  type = "CNAME"
}

