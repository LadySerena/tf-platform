terraform {
  backend "gcs" {
    bucket = "tel-platform-state.serenacodes.com"
  }
  required_version = "0.14.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.57.0"
    }
  }
}

provider "google" {
  project = "telvanni-platform"
  region  = "us-central1"
}