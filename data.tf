data "google_cloud_run_service" "discord_notifier" {
  name     = "discord-bot"
  location = "us-central1"
}

module "cloud_build_pub_sub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.9"

  topic      = "cloud-builds"
  project_id = data.google_project.project.project_id
  push_subscriptions = [
    {
      name                    = "push"
      ack_deadline_seconds    = 20
      push_endpoint           = data.google_cloud_run_service.discord_notifier.status[0].url
      enable_message_ordering = true
      expiration_policy       = ""
    }
  ]
}