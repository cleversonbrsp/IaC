output "bastion_session_ssh_connection_web" {
    value = oci_bastion_session.rmm_web_session.ssh_metadata.command
}