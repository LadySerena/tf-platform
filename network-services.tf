resource "google_dns_managed_zone" "default" {
  dns_name    = "serenacodes.com."
  name        = "serenacodes-zone"
  description = "dns zone for serenacodes.com"
}

resource "google_dns_managed_zone" "casa" {
  dns_name    = "serenacodes.casa."
  name        = "internal-zone"
  description = "dns zone for internal services"
}

resource "google_dns_record_set" "verification" {
  managed_zone = google_dns_managed_zone.default.name
  name         = "serenacodes.com."
  rrdatas      = ["google-site-verification=QGC_RBY5dkopavcMI_4ZFDloF5y3qVYp_o1dmch9zh0"]
  ttl          = 300
  type         = "TXT"
}

resource "google_dns_record_set" "casa_verification" {
  managed_zone = google_dns_managed_zone.casa.name
  name         = "serenacodes.casa."
  rrdatas      = ["google-site-verification=W2hPSRjSweImLdL3FF079j2bpqGyBqANWcCGzUz4WJY"]
  ttl          = 300
  type         = "TXT"
}

resource "google_dns_record_set" "blog" {
  managed_zone = google_dns_managed_zone.default.name
  name         = "blog.${google_dns_managed_zone.default.dns_name}"
  rrdatas = [
    "ladyserena.github.io."
  ]
  ttl  = 300
  type = "CNAME"
}

resource "google_dns_record_set" "polywork" {
  managed_zone = google_dns_managed_zone.default.name
  name         = "work.${google_dns_managed_zone.default.dns_name}"
  rrdatas = [
    "behavioural-pigeon-qrwa62ok4u5p883no18k9pz3.herokudns.com."
  ]
  ttl  = 300
  type = "CNAME"
}

resource "google_dns_record_set" "pi3" {
  managed_zone = google_dns_managed_zone.casa.name
  name         = "test-pi.${google_dns_managed_zone.casa.dns_name}"
  rrdatas = [
    "10.0.0.11"
  ]
  ttl  = 300
  type = "A"
}

resource "google_dns_record_set" "melchior" {
  managed_zone = google_dns_managed_zone.casa.name
  name         = "melchior.${google_dns_managed_zone.casa.dns_name}"
  rrdatas = [
    "10.0.0.18"
  ]
  ttl  = 300
  type = "A"
}

resource "google_dns_record_set" "balthasar" {
  managed_zone = google_dns_managed_zone.casa.name
  name         = "balthasar.${google_dns_managed_zone.casa.dns_name}"
  rrdatas = [
    "10.0.0.19"
  ]
  ttl  = 300
  type = "A"
}

resource "google_dns_record_set" "casper" {
  managed_zone = google_dns_managed_zone.casa.name
  name         = "casper.${google_dns_managed_zone.casa.dns_name}"
  rrdatas = [
    "10.0.0.20"
  ]
  ttl  = 300
  type = "A"
}

