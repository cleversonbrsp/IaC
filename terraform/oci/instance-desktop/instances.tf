resource "oci_core_instance" "instance" {
  availability_domain = var.oci_ad
  compartment_id      = oci_identity_compartment.crodrigues.id
  display_name        = "ubuntu-desktop"
  shape               = var.instance_shape

  shape_config {
    memory_in_gbs = var.instance_memory_gb
    ocpus         = var.instance_ocpus
  }

  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.pub_subnet.id
  }


  metadata = {
    ssh_authorized_keys = var.ssh_instances_key
    user_data = base64encode(file("cloud-init.sh"))
  }

  source_details {
    source_id   = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaav36a2jobmvkzym5zkrafwhma5itaqjf25wylliwlwnyzyunautmq"
    source_type = "image"
  }
}
