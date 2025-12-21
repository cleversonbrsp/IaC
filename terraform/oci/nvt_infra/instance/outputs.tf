# ========================================
# VPN Instance Outputs
# ========================================

output "instance_id" {
  description = "OCID of the VPN instance"
  value       = oci_core_instance.openvpn_instance.id
}

output "instance_display_name" {
  description = "Display name of the VPN instance"
  value       = oci_core_instance.openvpn_instance.display_name
}

output "instance_private_ip" {
  description = "Private IP address of the VPN instance"
  value       = oci_core_instance.openvpn_instance.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the VPN instance (if assigned)"
  value       = oci_core_instance.openvpn_instance.public_ip
}

output "instance_state" {
  description = "Current state of the VPN instance"
  value       = oci_core_instance.openvpn_instance.state
}

