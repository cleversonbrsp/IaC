################## selfhosted_instance ##################
resource "oci_core_instance" "selfhosted_instance" {
  # Required
  availability_domain                 = var.availability_domain
  compartment_id                      = oci_identity_compartment.oke_comp.id
  is_pv_encryption_in_transit_enabled = "true"
  shape                               = "VM.Standard.E4.Flex"
  shape_config {
    memory_in_gbs = "16"
    ocpus         = "1"
  }
  source_details {
    source_id   = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaa5sosu2p5am3wrlhorirpczba3rpxb3dnyjz3xjh6dhc2zwopbwvq"
    source_type = "image"
  }

  # Optional
  display_name = "selfhosted_instance"
  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.node_subnet.id
  }
  metadata = {
    ssh_authorized_keys = file("./keys/instance.pub")
  }
  preserve_boot_volume = false
}

################## vpn_instance ##################
resource "oci_core_instance" "vpn_instance" {
  # Required
  availability_domain                 = var.availability_domain
  compartment_id                      = oci_identity_compartment.oke_comp.id
  is_pv_encryption_in_transit_enabled = "true"
  shape                               = "VM.Standard.E4.Flex"
  shape_config {
    memory_in_gbs = "16"
    ocpus         = "1"
  }
  source_details {
    source_id   = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaa5sosu2p5am3wrlhorirpczba3rpxb3dnyjz3xjh6dhc2zwopbwvq"
    source_type = "image"
  }

  # Optional
  display_name = "vpn_instance"
  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.node_subnet.id
  }
  metadata = {
    ssh_authorized_keys = file("./keys/instance.pub")
  }
  preserve_boot_volume = false
}

############# DOCS #############
/* https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-compute/01-summary.htm
   https://docs.oracle.com/pt-br/iaas/Content/Compute/References/computeshapes.htm#flexible
   https://docs.oracle.com/en-us/iaas/images/image/9bff226a-3923-48d7-9931-c9869b36fbf1/
*/
