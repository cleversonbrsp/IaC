output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.instance.private_ip
}

# output "vcn_id" {
#   description = "VCN OCID"
#   value       = oci_core_vcn.lab_vcn.id
# }

# output "subnet_id" {
#   description = "Subnet OCID"
#   value       = oci_core_subnet.pub_subnet.id
# }

# output "compartment_id" {
#   description = "Compartment OCID"
#   value       = oci_identity_compartment.crodrigues.id
# }
