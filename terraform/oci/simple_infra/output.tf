output "instance_public_ip" {
  description = "Public IP address of the lab01 instance"
  value       = oci_core_instance.lab01_instance.public_ip
}