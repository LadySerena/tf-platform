locals {
  disk-id = "minecraft-data"
  zone    = "us-central1-a"
}

data "google_compute_image" "pi-image" {
  family  = "rbi-builder"
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

resource "google_compute_instance" "pi-image-builder" {
  name         = "pi-image-builder"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.pi-image.self_link
    }
  }

  network_interface {
    subnetwork = element(module.minecraft-vpc.subnets_self_links, 0)

    access_config {
      // Ephemeral public IP
    }
  }

  scheduling {
    preemptible = true
    automatic_restart = false
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = module.pi_image_service_account.email
    scopes = ["storage-rw", "logging-write", "monitoring-write", "trace", "compute-rw"]
  }
}