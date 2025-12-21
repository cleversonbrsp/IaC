# OCI PostgreSQL DB System - Terraform

This Terraform project provisions an Oracle Cloud Infrastructure (OCI) PostgreSQL DB System with optional network resources (VCN, subnet, and NSG).

## What it creates

### PostgreSQL DB System
- PostgreSQL database system with configurable instance count, memory, and OCPUs
- Management policy with maintenance window and backup configuration
- Storage configuration with IOPS and availability domain settings
- Optional restore from backup support

### Network Resources (Optional)
When `create_network_resources = true`, the following resources are created:
- **VCN**: Virtual Cloud Network for the database
- **Subnet**: Private or public subnet for the DB System
- **Security List**: Security rules for PostgreSQL access (port 5432) and SSH (port 22)
- **Network Security Group (NSG)**: Additional security rules for the DB System
- **Internet Gateway** (optional): Only created if subnet is public

## Prerequisites

- Terraform >= 1.5
- OCI account and configured CLI credentials in `~/.oci/config`
- PostgreSQL configuration OCID (`db_system_config_id`)
- Compartment OCID where resources will be created

## Variables

### Required Variables

- `oci_region` (string): OCI region (e.g., `us-ashburn-1`, `sa-saopaulo-1`)
- `oci_config_profile` (string): Profile name in `~/.oci/config`
- `comp_id` (string): Compartment OCID where to create resources
- `db_system_display_name` (string): Display name for the PostgreSQL DB System
- `db_system_config_id` (string): OCID of the PostgreSQL configuration to use
- `primary_db_endpoint_private_ip` (string): Private IP address for the primary database endpoint
- `availability_domain` (string): Availability Domain for storage (e.g., `giZW:US-ASHBURN-AD-1`)

### Required for New Database Deployments (source_type = "NONE")

- `db_username` (string): Database administrator username
- `db_password` (string) OR `db_password_secret_id` (string): Database password (prefer secret_id for production)

### Network Configuration

You have two options:

#### Option 1: Create New Network Resources
Set `create_network_resources = true` and configure:
- `vcn_cidr_block`: CIDR block for the VCN (e.g., `10.0.0.0/16`)
- `subnet_cidr_block`: CIDR block for the subnet (e.g., `10.0.10.0/24`)
- `subnet_prohibit_public_ip`: Set to `true` for private subnet, `false` for public
- `primary_db_endpoint_private_ip`: Must be within the subnet CIDR

#### Option 2: Use Existing Network Resources
Set `create_network_resources = false` and provide:
- `subnet_id`: OCID of existing subnet
- `nsg_ids`: List of existing NSG OCIDs

### Optional Variables

- `db_version` (string): PostgreSQL version (default: `14`)
- `instance_count` (number): Number of database instances (default: `1`)
- `instance_memory_size_in_gbs` (number): Memory per instance in GBs (default: `32`)
- `instance_ocpu_count` (number): OCPUs per instance (default: `2`)
- `db_system_shape` (string): Shape for the DB System (default: `PostgreSQL.VM.Standard.E4.Flex`)
- `backup_retention_days` (number): Days to retain backups (default: `7`)
- `source_type` (string): Source type - `NONE` for new DB or `BACKUP` for restore (default: `NONE`)
- `backup_id` (string): Required if `source_type = "BACKUP"`

See `variables.tf` for complete variable documentation.

## Example tfvars

Create `terraform.tfvars` (or copy `terraform.tfvars.example`):

### Using Existing Network Resources - New Database
```hcl
oci_region         = "us-ashburn-1"
oci_config_profile = "DEFAULT"
comp_id            = "ocid1.compartment.oc1..xxxx"

db_system_display_name = "postgresql-db-system"
db_system_config_id    = "ocid1.postgresqlconfiguration.oc1..xxxx"
primary_db_endpoint_private_ip = "10.20.0.27"
availability_domain   = "giZW:US-ASHBURN-AD-1"

# Database credentials (required for new database)
db_username = "admin"
db_password = "your-secure-password"
# OR use OCI Vault Secret (recommended):
# db_password_secret_id = "ocid1.vaultsecret.oc1..xxxx"

source_type = "NONE"

create_network_resources = false
subnet_id = "ocid1.subnet.oc1..xxxx"
nsg_ids   = ["ocid1.networksecuritygroup.oc1..xxxx"]
```

### Creating New Network Resources - New Database
```hcl
oci_region         = "us-ashburn-1"
oci_config_profile = "DEFAULT"
comp_id            = "ocid1.compartment.oc1..xxxx"

db_system_display_name = "postgresql-db-system"
db_system_config_id    = "ocid1.postgresqlconfiguration.oc1..xxxx"
primary_db_endpoint_private_ip = "10.0.10.10"
availability_domain   = "giZW:US-ASHBURN-AD-1"

# Database credentials (required for new database)
db_username = "admin"
db_password = "your-secure-password"
# OR use OCI Vault Secret (recommended):
# db_password_secret_id = "ocid1.vaultsecret.oc1..xxxx"

source_type = "NONE"

create_network_resources = true
vcn_cidr_block          = "10.0.0.0/16"
subnet_cidr_block       = "10.0.10.0/24"
subnet_prohibit_public_ip = true
```

## Usage

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan -out plan.tfplan

# Apply the configuration
terraform apply plan.tfplan
```

To destroy:
```bash
terraform destroy
```

## New Database vs Restore from Backup

### Creating a New Database

For a new database deployment, set `source_type = "NONE"` and provide credentials:

```hcl
source_type = "NONE"
db_username = "admin"
db_password = "your-secure-password"
# OR use OCI Vault Secret (recommended for production):
# db_password_secret_id = "ocid1.vaultsecret.oc1..xxxx"
```

**Note:** Credentials are required when creating a new database. Use OCI Vault secrets for production environments instead of plain text passwords.

### Restore from Backup

To restore from a backup, set:
```hcl
source_type = "BACKUP"
backup_id   = "ocid1.postgresqlbackup.oc1..xxxx"
```

**Note:** When restoring from backup, credentials are not required as they are restored from the backup.

## Notes

- The provider uses `var.oci_config_profile` and `var.oci_region` in `main.tf`
- Lifecycle rules ignore changes to Oracle-managed tags (`Oracle-Tags.CreatedBy`, `Oracle-Tags.CreatedOn`)
- Security lists and NSG rules allow PostgreSQL access (port 5432) from the VCN CIDR
- SSH access (port 22) is allowed from the VCN CIDR for management purposes
- Adjust security rules in `network.tf` based on your security requirements
- The `primary_db_endpoint_private_ip` must be available and within the subnet CIDR range

## File Structure

```
.
├── main.tf                    # Provider configuration
├── variables.tf               # Variable definitions
├── psql.tf                    # PostgreSQL DB System resource
├── network.tf                 # Network resources (VCN, subnet, NSG)
├── terraform.tfvars           # Variable values (not in git)
├── terraform.tfvars.example   # Example variable values
└── README.md                  # This file
```

