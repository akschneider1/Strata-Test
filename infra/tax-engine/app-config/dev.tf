module "dev_config" {
  source                          = "./env-config"
  project_name                    = local.project_name
  app_name                        = local.app_name
  default_region                  = module.project_config.default_region
  environment                     = "dev"
  network_name                    = "dev"
  domain_name                     = null
  enable_https                    = false
  has_database                    = local.has_database
  has_incident_management_service = local.has_incident_management_service
  enable_notifications            = local.enable_notifications
  enable_document_data_extraction = local.enable_document_data_extraction
  enable_sms_notifications        = local.enable_sms_notifications
  enable_storage_malware_scanning = local.enable_storage_malware_scanning

  # The tax rules need about 1.5 GB of memory once loaded, and a calculation
  # uses one CPU core. Each container runs one worker (see gunicorn.conf.py)
  # and handles about one new calculation a second; add containers for more.
  service_cpu                    = 1024
  service_memory                 = 3072
  service_desired_instance_count = 1

  # Enable and configure identity provider.
  enable_identity_provider = local.enable_identity_provider

  # Support local development against the dev instance.
  extra_identity_provider_callback_urls = ["http://localhost"]
  extra_identity_provider_logout_urls   = ["http://localhost"]

  # Enables ECS Exec access for debugging or jump access.
  # See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html
  # Defaults to `false`. Uncomment the next line to enable.
  # enable_command_execution = true

  # Uncomment to override default feature flag values
  # feature_flag_overrides = {
  #   BAR = true
  # }
}
