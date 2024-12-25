provider "oci" {
  region = "us-ashburn-1"
}

resource "oci_core_instance" "generated_oci_core_instance" {
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "DISABLED"
			name = "WebLogic Management Service"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Vulnerability Scanning"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Oracle Java Management Service"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Oracle Autonomous Linux"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "OS Management Service Agent"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "OS Management Hub Agent"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Management Agent"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Custom Logs Monitoring"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Compute RDMA GPU Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Run Command"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Compute HPC RDMA Auto-Configuration"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Compute HPC RDMA Authentication"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Cloud Guard Workload Protection"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Block Volume Management"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Bastion"
		}
	}
	availability_config {
		is_live_migration_preferred = "true"
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = "agak:US-ASHBURN-AD-1"
	compartment_id = "ocid1.compartment.oc1..aaaaaaaatwrjxfdmsdy3smjqwzvg57uqqrkszcc6yhg7ls4uesvyy4bbvd4a"
	create_vnic_details {
		assign_ipv6ip = "false"
		assign_private_dns_record = "true"
		assign_public_ip = "true"
		subnet_id = "${oci_core_subnet.generated_oci_core_subnet.id}"
	}
	display_name = "mkd-ubuntu"
	instance_options {
		are_legacy_imds_endpoints_disabled = "false"
	}
	metadata = {
		"ssh_authorized_keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXnQEIe7j2OsrGgEgFtt0xVJXmjltqp7j27aaSqSi2GTD593sCs5da7Ik6jvhk+K/D9yibD/vQvTxTXDVU+cPK/j7EPfgUZ3zy5Bpn9Kcz6K4U/4OOljpCtpzDgJ8ezwwZ7REupncsTA2e2keGXgYRo9sSZkKq2Y36eCGIdDL9Mnuj37tflu9yddONcKIWi1zBACYo3UTa6c3ZZCu4/Top4IuqR+V6kqKHaT837wMmfEGawt1goxLt/IvaHbR2MuFw+vMJeDZNZKXpXUtvmNEpkGf3cZ2qWz9SzOxPTh/dPbYSi8wUDMNWVP0H5snWKIo6QTt+//W5gaSVwIzrA685 ssh-key-2024-12-02"
	}
	shape = "VM.Standard.E5.Flex"
	shape_config {
		memory_in_gbs = "12"
		ocpus = "1"
	}
	source_details {
		source_id = "ocid1.image.oc1.iad.aaaaaaaaytxogd5q5yygzprjpywy5jfetxtvlagoxvem5myytngb774tovda"
		source_type = "image"
	}
}

resource "oci_core_vcn" "generated_oci_core_vcn" {
	cidr_block = "10.0.0.0/16"
	compartment_id = "ocid1.compartment.oc1..aaaaaaaatwrjxfdmsdy3smjqwzvg57uqqrkszcc6yhg7ls4uesvyy4bbvd4a"
	display_name = "vcn-mkd"
	dns_label = "vcn12021026"
}

resource "oci_core_subnet" "generated_oci_core_subnet" {
	cidr_block = "10.0.0.0/24"
	compartment_id = "ocid1.compartment.oc1..aaaaaaaatwrjxfdmsdy3smjqwzvg57uqqrkszcc6yhg7ls4uesvyy4bbvd4a"
	display_name = "pubsub"
	dns_label = "subnet12021026"
	route_table_id = "${oci_core_vcn.generated_oci_core_vcn.default_route_table_id}"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_internet_gateway" "generated_oci_core_internet_gateway" {
	compartment_id = "ocid1.compartment.oc1..aaaaaaaatwrjxfdmsdy3smjqwzvg57uqqrkszcc6yhg7ls4uesvyy4bbvd4a"
	display_name = "Internet Gateway vcn-mkd"
	enabled = "true"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_default_route_table" "generated_oci_core_default_route_table" {
	route_rules {
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = "${oci_core_internet_gateway.generated_oci_core_internet_gateway.id}"
	}
	manage_default_resource_id = "${oci_core_vcn.generated_oci_core_vcn.default_route_table_id}"
}