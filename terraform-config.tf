terraform {
  backend "gcs" {
    bucket = "tel-platform-state.serenacodes.com"
  }
  required_version = "1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.89.0"
    }
  }
}

provider "google" {
  project = "telvanni-platform"
  region  = "us-central1"
}