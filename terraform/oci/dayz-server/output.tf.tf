output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.dayz-server-instance.public_ip
}