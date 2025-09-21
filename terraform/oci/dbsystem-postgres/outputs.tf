# Compartment Outputs
output "compartment_id" {
  description = "OCID of the compartment used for resources"
  value       = local.compartment_id
}

output "compartment_name" {
  description = "Name of the compartment"
  value       = var.create_compartment ? oci_identity_compartment.postgres[0].name : "Existing compartment"
}

# Network Outputs
output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.postgres_vcn.id
}

output "vcn_cidr_block" {
  description = "CIDR block of the VCN"
  value       = oci_core_vcn.postgres_vcn.cidr_blocks[0]
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = oci_core_subnet.postgres_private_subnet.id
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = oci_core_subnet.postgres_private_subnet.cidr_block
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.postgres_public_subnet.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = oci_core_subnet.postgres_public_subnet.cidr_block
}

output "network_security_group_id" {
  description = "OCID of the Network Security Group"
  value       = oci_core_network_security_group.postgres_nsg.id
}

# PostgreSQL Database System Outputs
output "postgres_db_system_id" {
  description = "OCID of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgres_db_system.id
}

output "postgres_db_system_display_name" {
  description = "Display name of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgres_db_system.display_name
}

output "postgres_db_system_state" {
  description = "State of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgres_db_system.state
}

output "postgres_db_system_shape" {
  description = "Shape of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgres_db_system.shape
}

output "postgres_db_version" {
  description = "PostgreSQL database version"
  value       = oci_psql_db_system.postgres_db_system.db_version
}

output "postgres_instance_count" {
  description = "Number of instances in the DB System"
  value       = oci_psql_db_system.postgres_db_system.instance_count
}

output "postgres_instance_ocpu_count" {
  description = "Number of OCPUs per instance"
  value       = oci_psql_db_system.postgres_db_system.instance_ocpu_count
}

output "postgres_instance_memory_size_in_gbs" {
  description = "Memory size in GBs per instance"
  value       = oci_psql_db_system.postgres_db_system.instance_memory_size_in_gbs
}

# Database System Information
output "postgres_db_system_info" {
  description = "PostgreSQL DB System basic information"
  value = {
    id             = oci_psql_db_system.postgres_db_system.id
    display_name   = oci_psql_db_system.postgres_db_system.display_name
    state          = oci_psql_db_system.postgres_db_system.state
    admin_username = var.db_admin_username
  }
  sensitive = false
}

# Database Connection Information
output "postgres_connection_info" {
  description = "PostgreSQL connection information"
  value = {
    username = var.db_admin_username
    password = "*** SENSITIVE - Check terraform.tfvars ***"
    port     = 5432
    database = "postgres"
  }
  sensitive = false
}

# Network Information
output "postgres_network_details" {
  description = "Network configuration details"
  value = {
    subnet_id = oci_core_subnet.postgres_private_subnet.id
    nsg_id    = oci_core_network_security_group.postgres_nsg.id
  }
}

# Configuration Information
output "postgres_config_id" {
  description = "OCID of the PostgreSQL configuration used"
  value       = oci_psql_db_system.postgres_db_system.config_id
}

# PostgreSQL Endpoint Information
output "postgres_endpoint" {
  description = "PostgreSQL database endpoint information"
  value = {
    private_ip = local.postgres_private_ip
    port       = 5432
    fqdn       = "Not available (private subnet)"
  }
}

# Bastion Information
output "bastion_info" {
  description = "Bastion service information for PostgreSQL access"
  value = {
    bastion_id      = oci_bastion_bastion.postgres_bastion.id
    bastion_name    = oci_bastion_bastion.postgres_bastion.name
    bastion_state   = oci_bastion_bastion.postgres_bastion.state
    target_subnet   = oci_bastion_bastion.postgres_bastion.target_subnet_id
    session_created = var.create_bastion_session
    session_id      = var.create_bastion_session ? oci_bastion_session.postgres_session[0].id : "Not created"
  }
}

# Dynamic Connection Commands
output "connection_commands" {
  description = "Ready-to-use commands for connecting to PostgreSQL (IPs are dynamic)"
  value = {
    create_bastion_session = "oci bastion session create-port-forwarding --bastion-id ${oci_bastion_bastion.postgres_bastion.id} --display-name 'postgres-session' --key-type 'PUB' --ssh-public-key-file ~/.ssh/oci-instance.pub --target-port 5432 --target-private-ip '${local.postgres_private_ip}' --session-ttl 10800 --wait-for-state SUCCEEDED"
    ssh_tunnel_template = "ssh -i ~/.ssh/oci-instance -N -L 5432:${local.postgres_private_ip}:5432 -p 22 <SESSION_ID>@host.bastion.us-ashburn-1.oci.oraclecloud.com"
    postgres_connect = "PGPASSWORD='${var.db_admin_password}' psql -h localhost -U ${var.db_admin_username} -d postgres"
    note = "Replace <SESSION_ID> with the session ID returned from the first command"
  }
  sensitive = true
}

# Connection Instructions
output "connection_instructions" {
  description = "Instructions for connecting to PostgreSQL"
  value = {
    step_1 = "Run the create_bastion_session command from connection_commands output"
    step_2 = "Copy the SESSION_ID from the response"
    step_3 = "Run the ssh_tunnel_template command (replace <SESSION_ID>)"
    step_4 = "In another terminal, run the postgres_connect command"
    note   = "All commands use dynamic IPs and will update automatically"
  }
}

# Input Variables for Reference
output "configuration_summary" {
  description = "Summary of the configuration used"
  value = {
    project_name   = var.project_name
    environment    = var.environment
    region         = var.oci_region
    db_version     = var.db_version
    instance_shape = var.db_system_shape
  }
}
