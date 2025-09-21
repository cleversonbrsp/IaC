# Local values for computed resources and standardized naming
locals {
  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Compartment ID - use existing or created one
  compartment_id = var.create_compartment ? oci_identity_compartment.postgres[0].id : var.compartment_id

  # Common freeform tags applied to all resources
  common_tags = merge(
    var.common_tags,
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "ManagedBy"   = "Terraform"
    }
  )

  # Network configuration
  vcn_display_name = "${local.name_prefix}-vcn"
  vcn_dns_label    = replace("${var.project_name}${var.environment}", "-", "")

  # Subnet configurations
  private_subnet_name = "${local.name_prefix}-private-subnet"
  public_subnet_name  = "${local.name_prefix}-public-subnet"

  # Security list names
  private_security_list_name = "${local.name_prefix}-private-sl"
  public_security_list_name  = "${local.name_prefix}-public-sl"

  # Database system configuration
  db_system_name = var.db_system_display_name != "" ? var.db_system_display_name : "${local.name_prefix}-postgres"

  # Network Security Group name
  nsg_name = "${local.name_prefix}-postgres-nsg"

  # Get availability domains data
  availability_domain_name = var.availability_domain
  
  # PostgreSQL dynamic IP (will be available after DB System creation)
  postgres_private_ip = try(oci_psql_db_system.postgres_db_system.network_details[0].primary_db_endpoint_private_ip, "Not yet created")
}

# Data sources for availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_id
}

# Get the first availability domain if not specified
locals {
  ad_name = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
}
