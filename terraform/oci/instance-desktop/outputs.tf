output "tenancy_ocid" {
  description = "Tenancy OCID informado em var.tenancy_ocid (referência; não é inferido pelo provider)."
  value       = var.tenancy_ocid
}

output "compartment_id" {
  description = "OCID do compartment filho criado."
  value       = local.compartment_id
}

output "vcn_id" {
  description = "OCID da VCN."
  value       = oci_core_vcn.vcn.id
}

output "vpn_subnet_id" {
  description = "OCID da subnet pública do OpenVPN."
  value       = oci_core_subnet.vpn.id
}

output "private_subnet_id" {
  description = "OCID da subnet privada do desktop (sem IP público na VNIC)."
  value       = oci_core_subnet.private.id
}

output "vpn_instance_id" {
  description = "OCID da instância OpenVPN."
  value       = oci_core_instance.vpn.id
}

output "vpn_public_ip" {
  description = "IP público do servidor OpenVPN (conexão UDP na porta openvpn_port)."
  value       = data.oci_core_vnic.vpn_vnic.public_ip_address
}

output "vpn_ssh_cmd" {
  description = "SSH no servidor OpenVPN (administração)."
  value       = "ssh -i ${var.ssh_private_key_path} ${var.cloud_init_user}@${data.oci_core_vnic.vpn_vnic.public_ip_address}"
}

output "openvpn_menu_cmd" {
  description = "No servidor VPN: menu interativo (add/revoke/remove) — mesmo modelo wln/psql."
  value       = "sudo bash /opt/openvpn-ubuntu-install.sh"
}

output "desktop_instance_id" {
  description = "OCID da instância do desktop."
  value       = oci_core_instance.desktop.id
}

output "desktop_private_ip" {
  description = "IP privado do desktop (SSH/RDP após conectar no VPN)."
  value       = data.oci_core_vnic.desktop_vnic.private_ip_address
}

output "ssh_cmd" {
  description = "SSH no desktop pelo IP privado (após VPN ativa)."
  value       = "ssh -i ${var.ssh_private_key_path} ${var.cloud_init_user}@${data.oci_core_vnic.desktop_vnic.private_ip_address}"
}

output "rdp_hint" {
  description = "RDP para o IP privado do desktop, porta 3389 (após VPN)."
  value       = "${data.oci_core_vnic.desktop_vnic.private_ip_address}:3389"
}

output "vpn_access_note" {
  description = "Lembrete de rede."
  value       = "O cliente OpenVPN recebe o pool 10.8.0.0/24 (script) e rota para vcn_cidr. Ajuste openvpn_client_cidr e regras do desktop para coincidir. Ingress do desktop: apenas vpn_subnet_cidr e openvpn_client_cidr."
}
