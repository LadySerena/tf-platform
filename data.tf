data "google_cloudfunctions_function" "discord_notifier" {
  name = "discord-notifier"
}

module "cloud_build_pub_sub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 3.1"

  topic      = "cloud-builds"
  project_id = data.google_project.project.project_id
  push_subscriptions = [
    {
      name                    = "push"
      ack_deadline_seconds    = 20
      push_endpoint           = data.google_cloudfunctions_function.discord_notifier.https_trigger_url
      enable_message_ordering = true
      expiration_policy       = ""
    }
  ]
}
