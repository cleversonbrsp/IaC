locals {
  compartment_id = oci_identity_compartment.desktop.id

  selected_ad_name = var.availability_domain_name

  oracle_services_network = one(data.oci_core_services.all_oci_services.services)

  resolved_image_id   = var.instance_image_id
  vpn_source_image_id = var.vpn_image_id
}
