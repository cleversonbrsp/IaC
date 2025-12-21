module "iam" {
  source                      = "/home/cleverson/Documents/github/usage-reports-to-adw/terraform/modules/iam"
  iam_enabled                 = var.option_iam == "New IAM Dynamic Group and Policy will be created"
  tenancy_ocid                = var.tenancy_ocid
  compartment_id              = var.compartment_ocid
  db_secret_compartment_id    = var.db_secret_compartment_id
  policy_name                 = var.new_policy_name
  dynamic_group_name          = var.new_dynamic_group_name
  dynamic_group_matching_rule = "ALL {instance.id = '${module.compute.compute_id}'}"
  service_tags                = var.service_tags
}

