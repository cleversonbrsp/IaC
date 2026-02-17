output "instance_public_ip" {
  description = "Public IP address of the DayZ server instance"
  value       = oci_core_instance.dayz-server-instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the DayZ server instance"
  value       = oci_core_instance.dayz-server-instance.private_ip
}

output "instance_id" {
  description = "OCID of the DayZ server instance"
  value       = oci_core_instance.dayz-server-instance.id
}

output "instance_display_name" {
  description = "Display name of the DayZ server instance"
  value       = oci_core_instance.dayz-server-instance.display_name
}

output "ssh_connection" {
  description = "SSH connection command (note: use 'ubuntu' user initially, not 'dayz')"
  value       = "ssh -i ~/.ssh/instance-oci.key ubuntu@${oci_core_instance.dayz-server-instance.public_ip}"
}

output "dayz_server_info" {
  description = "Informações do servidor DayZ"
  value = {
    public_ip     = oci_core_instance.dayz-server-instance.public_ip
    private_ip    = oci_core_instance.dayz-server-instance.private_ip
    game_port_tcp = "2302"
    game_port_udp = "2302"
    additional_udp_ports = "2303-2305"
    ssh_user      = "ubuntu"
    dayz_user     = "dayz"
    install_command = "sudo su - dayz && ./install_dayz.sh"
  }
}

