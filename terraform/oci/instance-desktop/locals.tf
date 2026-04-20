locals {
  compartment_id = oci_identity_compartment.desktop.id

  selected_ad_name = var.availability_domain_name

  oracle_services_network = one(data.oci_core_services.all_oci_services.services)

  resolved_image_id   = var.instance_image_id
  vpn_source_image_id = var.vpn_image_id != "" ? var.vpn_image_id : var.instance_image_id

  # MIME multipart: cloud-config desliga package_update/upgrade do cloud-init para não disputar
  # o lock do apt com este script shell (primeiro deploy confiável).
  desktop_cloud_init_userdata = join("", [
    "Content-Type: multipart/mixed; boundary=\"oci-desktop-ci\"\n",
    "MIME-Version: 1.0\n",
    "\n",
    "--oci-desktop-ci\n",
    "Content-Type: text/cloud-config; charset=\"utf-8\"\n",
    "\n",
    "#cloud-config\n",
    "package_update: false\n",
    "package_upgrade: false\n",
    "\n",
    "--oci-desktop-ci\n",
    "Content-Type: text/x-shellscript; charset=\"utf-8\"\n",
    "\n",
    file("${path.module}/scripts/cloud-init-desktop.sh"),
    "\n",
    "--oci-desktop-ci--\n",
  ])
}
