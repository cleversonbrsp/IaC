resource "oci_core_instance" "generated_oci_core_instance" {
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "ENABLED"
			name = "Vulnerability Scanning"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Oracle Java Management Service"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "OS Management Service Agent"
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
	availability_domain = "FOjF:SA-SAOPAULO-1-AD-1"
	compartment_id = "ocid1.compartment.oc1..aaaaaaaahr4m4tasfqdhos2obvovgohfxq66yf3ylnvj43hvxclmlszy2eeq"
	create_vnic_details {
		assign_ipv6ip = "false"
		assign_private_dns_record = "true"
		assign_public_ip = "true"
		subnet_id = "${oci_core_subnet.generated_oci_core_subnet.id}"
	}
	display_name = "instance-homolog"
	instance_options {
		are_legacy_imds_endpoints_disabled = "false"
	}
	metadata = {
		"ssh_authorized_keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRalpa/RidCCiymS5bpeb/pXm6Ms+ZVvyJPJri0Tt8meyrgeTFlm7aSLtMpgOck31j5pg0Af2NZiv+5T9fkhDF7493N2z53M6yBnA2CfdWsCsohBL36NoapeFS/K/1Ctt4pseDghMH49kn2d8v4eKfjJKsXANeiyACtH5oMlNSpdXZzNhejmL9qomQ8C/9PfGRoo40MGjGcrJWd8loWHUCrBY/v9xQGYmMCeKO2hORZ3uk5/VvprzCsN1cLwZ8fKRUOFaQFkFEVoxe43GJcJecSHBYjhSodWVLA8Zw7KSdcaS5Rk8xp8qLL7OF3+IXETBFFazbocTTFDgfgemxDm9N ssh-key-2023-09-01"
	}
	shape = "VM.Standard.A1.Flex"
	shape_config {
		memory_in_gbs = "4"
		ocpus = "1"
	}
	source_details {
		source_id = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaa7qtue4pyzwomqsj77gqvcfce5uv4x4b2vlxgur3knk7k7wwkexma"
		source_type = "image"
	}
}

resource "oci_core_vcn" "generated_oci_core_vcn" {
	cidr_block = "10.0.0.0/16"
	compartment_id = "ocid1.compartment.oc1..aaaaaaaahr4m4tasfqdhos2obvovgohfxq66yf3ylnvj43hvxclmlszy2eeq"
	display_name = "vcn-homolog"
	dns_label = "vcn02071739"
}

resource "oci_core_subnet" "generated_oci_core_subnet" {
	cidr_block = "10.0.0.0/24"
	compartment_id = "ocid1.compartment.oc1..aaaaaaaahr4m4tasfqdhos2obvovgohfxq66yf3ylnvj43hvxclmlszy2eeq"
	display_name = "subnet-homolog"
	dns_label = "subnet02071739"
	route_table_id = "${oci_core_vcn.generated_oci_core_vcn.default_route_table_id}"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_internet_gateway" "generated_oci_core_internet_gateway" {
	compartment_id = "ocid1.compartment.oc1..aaaaaaaahr4m4tasfqdhos2obvovgohfxq66yf3ylnvj43hvxclmlszy2eeq"
	display_name = "Internet Gateway vcn-homolog"
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
