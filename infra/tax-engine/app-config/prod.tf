module "prod_config" {
  source                          = "./env-config"
  project_name                    = local.project_name
  app_name                        = local.app_name
  default_region                  = module.project_config.default_region
  environment                     = "prod"
  network_name                    = "prod"
  domain_name                     = null
  enable_https                    = false
  has_database                    = local.has_database
  has_incident_management_service = local.has_incident_management_service
  enable_identity_provider        = local.enable_identity_provider
  enable_notifications            = local.enable_notifications
  enable_document_data_extraction = local.enable_document_data_extraction
  enable_sms_notifications        = local.enable_sms_notifications
  enable_storage_malware_scanning = local.enable_storage_malware_scanning

  # The tax rules need about 3 GB of memory once loaded (2025 rules plus the
  # 2027 graduated-rate rules), and a calculation uses one CPU core. Each container runs one worker (see gunicorn.conf.py)
  # and handles about one new calculation a second; add containers for more.
  service_cpu                    = 1024
  service_memory                 = 4096
  service_desired_instance_count = 3

  # Enables ECS Exec access for debugging or jump access.
  # Defaults to `false`. Uncomment the next line to enable.
  # ⚠️ Warning! It is not recommended to enable this in a production environment.
  # enable_command_execution = true
}
