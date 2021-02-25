locals {
  disk-id = "minecraft-data"
}

data "google_compute_image" "minecraft-image" {
  family  = "serena-minecraft"
  project = data.google_project.project.name
}

module "minecraft-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.0"

  project_id   = data.google_project.project.project_id
  network_name = "minecraft-vpc"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "192.168.10.0/25"
      subnet_region = "us-central1"
    },
  ]

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
  ]
}
module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = data.google_project.project.project_id
  network_name = module.minecraft-vpc.network_name

  rules = [
    {
      name        = "allow-ssh-iap-ingress"
      priority    = 1000
      description = "allow ssh via identity aware proxy see here for range https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule"
      direction   = "INGRESS"
      ranges = [
      "35.235.240.0/20"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [
        {
          protocol = "tcp"
          ports = [
          "22"]
      }]
      deny       = []
      log_config = null
    },
    {
      name        = "allow-minecraft"
      priority    = 1001
      description = "allows friends on public internet to access minecraft"
      direction   = "INGRESS"
      ranges = [
      "0.0.0.0/0"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [
        {
          protocol = "tcp"
          ports = [
          "25565"]
        },
        {
          protocol = "udp"
          ports = [
          "25565"]
        }
      ]
      deny       = []
      log_config = null
    }
  ]
}

#resource "google_compute_disk" "minecraft-data" {
#  name = "minecraft-data"
#  type = "pd-ssd"
#  size = 30
#  zone = "us-central1-f"
#}
#
#resource "google_compute_instance" "minecraft-test" {
#  name         = "minecraft-test"
#  machine_type = "e2-medium"
#  zone         = "us-central1-f"
#  metadata = {
#    "mount-point"       = "/minecraft-data/"
#    "owner"             = "minecraft"
#    "disk-id"           = local.disk-id
#    "volume-group-name" = "minecraft-volume-group"
#    "lvm-name"          = "minecraft-logical-volume"
#    "dbus-secret-name"  = "mc-dbus-api-htpasswd"
#    "service-name"      = "minecraft.service"
#    "tls-secret-name"   = "minecraft-dbus-key"
#    "tls-cert"          = <<EOT
#    -----BEGIN CERTIFICATE-----
#    MIIFCjCCAvKgAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwVTELMAkGA1UEBhMCVVMx
#    EjAQBgNVBAgMCU1pbm5lc290YTETMBEGA1UECgwKU2VyZW5hY29ycDEdMBsGA1UE
#    AwwUU2VyZW5hSW50ZXJtZWRpYXRlQ0EwHhcNMjEwMjIxMDM0OTA2WhcNMjIwMzAz
#    MDM0OTA2WjCBkjELMAkGA1UEBhMCVVMxEjAQBgNVBAgMCU1pbm5lc290YTEUMBIG
#    A1UEBwwLTWlubmVhcG9saXMxEzARBgNVBAoMClNlcmVuYWNvcnAxRDBCBgNVBAMM
#    O21pbmVjcmFmdC1zZXJ2ZXIudXMtY2VudHJhbDEtYS5jLnRlbHZhbm5pLXBsYXRm
#    b3JtLmludGVybmFsMIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQADDSDzwx+75j/
#    4rOcO2DJMNVmDyVTOsixc6GyInhYUjUJI64Z5KevRmZHe3zu6/X8Wiln1Jg2aXGW
#    bJEC7vwncD8ANyR73VGBe9Jal41lXc44WpMKfaaUCFHaEV+3sx0GsBR2oXPLoEX8
#    WfZraDnbgQyHuyIKNJB/b3SXpW5Vlm/xu4KjggEsMIIBKDAJBgNVHRMEAjAAMBEG
#    CWCGSAGG+EIBAQQEAwIGQDAzBglghkgBhvhCAQ0EJhYkT3BlblNTTCBHZW5lcmF0
#    ZWQgU2VydmVyIENlcnRpZmljYXRlMB0GA1UdDgQWBBRKPVk5n4TpcmosSJjfLlw8
#    MgA01zCBjgYDVR0jBIGGMIGDgBSXCCBIk4WTt0Aa7hPGE139Eu/3hqFnpGUwYzEL
#    MAkGA1UEBhMCVVMxEjAQBgNVBAgMCU1pbm5lc290YTEUMBIGA1UEBwwLTWlubmVh
#    cG9saXMxEzARBgNVBAoMClNlcmVuYWNvcnAxFTATBgNVBAMMDFNlcmVuYVJvb3RD
#    QYICEAAwDgYDVR0PAQH/BAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA0GCSqG
#    SIb3DQEBCwUAA4ICAQCZtthahEytxCnxWYMJSHekzExPzAU/aT8dWkH1/AsP5zyb
#    JEHMlCTcLhbthFoNsH7f2thJ1eHeCyWzjiYy1w3+dM0TjPb5CrejyatTTyej05S1
#    vmHAAFMIv0WfIyxbAusUwhYKnFg6djhci8RFn5FkUuSc+DaL/NGaB6RMgImxfPr/
#    FTxeL/AQGGo73oGt1QC/lle52/dEVTLI3gTHt7MZHRt9ZeWpPtvqz73+hgijfHfS
#    P0PJEduhJ+aIrWx6Qsp1VBTSU7JNekoOLN1Ks1BdPXQ7kklKbBx9LVDMpDxGRsKd
#    YwZPS6MtzXqLChxEzet17mhlLS7Bzvw6iKHQhacQwdyy7bIMVItPPOvzjYAEo3je
#    4kE3ZTI/KtlKpAtT9+iv8j8WJK6XOReiDCDVoTCCa9DWrRNoyrrl4znf7U47uZ82
#    DlKsJsGWrq+eHxhTCzQxWI+RcOd7camabwA3hobVvfQJxNCXVWtDAI+Ky91cL7R2
#    F0WAEr5P0AscSSKIrHIUtD6SivMJuCLwUNoQRr5AibpEIEUQFL7KTxL5YPapcg/h
#    Ntz+g/Vvzd485B8ugUzWpkqRwyxl6fGDmnGqjwPDf1NYvoD75I9BZMEt76GZei5k
#    CskqQ1/orfhW2Ya0MbbzyFg6KuJaKQs+eR4jv1x/pXQaZBvXEDy930diXX/MiQ==
#    -----END CERTIFICATE-----
#    EOT
#
#  }
#
#  metadata_startup_script = file("scripts/minecraft-disk.sh")
#
#  boot_disk {
#    initialize_params {
#      image = data.google_compute_image.minecraft-image.self_link
#    }
#  }
#  attached_disk {
#    source      = google_compute_disk.minecraft-data.self_link
#    device_name = local.disk-id
#  }
#  network_interface {
#    subnetwork = element(module.minecraft-vpc.subnets_self_links, 0)
#    access_config {
#
#    }
#  }
#}