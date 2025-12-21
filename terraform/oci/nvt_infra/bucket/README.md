# OCI Object Storage Bucket - Terraform Module

This Terraform module creates and manages an Oracle Cloud Infrastructure (OCI) Object Storage bucket with comprehensive configuration options.

## Features

- ✅ **Automatic namespace detection** - Fetches object storage namespace automatically using data source
- ✅ **Structured variable organization** - Variables grouped into logical objects
- ✅ **Multiple retention rules support** - Configure multiple retention rules as a list
- ✅ **Variable validation** - Input validation for better error handling
- ✅ **Comprehensive outputs** - Exposes all relevant bucket information
- ✅ **Flexible configuration** - Support for all bucket features including KMS encryption, versioning, auto-tiering

## Project Structure

```
bucket/
├── main.tf              # Provider configuration
├── variables.tf         # Variable declarations
├── data.tf              # Data sources (namespace lookup)
├── storage_bucket.tf    # Bucket resource definition
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable values (customize this)
└── README.md            # This file
```

## Usage

### Basic Configuration

1. Copy and customize `terraform.tfvars`:

```hcl
oci_region         = "sa-saopaulo-1"
oci_config_profile = "devopsguide"
compartment_id     = "ocid1.compartment.oc1..aaaaaaa..."
bucket_name        = "my-bucket"
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

### Advanced Configuration

#### With Retention Rules

```hcl
retention_rules = [
  {
    display_name     = "30-Day Retention"
    time_amount      = 30
    time_unit        = "DAYS"
    time_rule_locked = null
  },
  {
    display_name     = "1-Year Archive"
    time_amount      = 1
    time_unit        = "YEARS"
    time_rule_locked = "2025-12-31T23:59:59Z"
  }
]
```

#### With KMS Encryption

```hcl
bucket_config = {
  kms_key_id = "ocid1.kmskey.oc1.sa-saopaulo-1.aaaaaaa..."
  # ... other settings
}
```

#### With Auto-Tiering

```hcl
bucket_config = {
  auto_tiering = "InfrequentAccess"
  storage_tier = "Standard"
}
```

## Variables

### Required Variables

| Variable | Description | Type |
|----------|-------------|------|
| `oci_region` | OCI region identifier | `string` |
| `compartment_id` | OCID of the compartment | `string` |
| `bucket_name` | Name of the bucket (1-63 chars, lowercase alphanumeric) | `string` |

### Optional Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `oci_config_profile` | OCI config profile name | `string` | `"DEFAULT"` |
| `bucket_namespace` | Object storage namespace (auto-fetched if not provided) | `string` | `null` |
| `bucket_config` | Bucket configuration object | `object` | `{}` |
| `retention_rules` | List of retention rules | `list(object)` | `[]` |
| `defined_tags` | Defined tags map | `map(string)` | `{}` |
| `freeform_tags` | Freeform tags map | `map(string)` | `{}` |

### Bucket Config Object

```hcl
bucket_config = {
  access_type           = "NoPublicAccess"  # NoPublicAccess | ObjectRead | ObjectReadWithoutList
  auto_tiering          = null              # null | "InfrequentAccess"
  storage_tier          = "Standard"        # Standard | Archive
  versioning            = "Disabled"         # Enabled | Disabled
  object_events_enabled = false
  metadata              = {}                # map(string)
  kms_key_id           = null               # string (OCID)
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `bucket_id` | The OCID of the bucket |
| `bucket_name` | The name of the bucket |
| `bucket_namespace` | The namespace of the bucket |
| `bucket_uri` | The full URI of the bucket |
| `bucket_etag` | The entity tag (ETag) for the bucket |
| `bucket_created_by` | The OCID of the user who created the bucket |
| `bucket_time_created` | The date and time the bucket was created |
| `bucket_compartment_id` | The OCID of the compartment containing the bucket |
| `bucket_access_type` | The type of public access enabled on this bucket |
| `bucket_storage_tier` | The storage tier type assigned to the bucket |
| `bucket_versioning` | The versioning status on the bucket |

## Examples

### Example 1: Basic Bucket

```hcl
bucket_name = "my-app-bucket"
bucket_config = {
  access_type = "NoPublicAccess"
  versioning  = "Enabled"
}
```

### Example 2: Bucket with Encryption and Retention

```hcl
bucket_name = "secure-archive-bucket"
bucket_config = {
  kms_key_id           = "ocid1.kmskey.oc1..."
  storage_tier         = "Archive"
  object_events_enabled = true
}

retention_rules = [
  {
    display_name = "7-Year Retention"
    time_amount  = 7
    time_unit    = "YEARS"
  }
]
```

### Example 3: Public Read Bucket

```hcl
bucket_name = "public-assets-bucket"
bucket_config = {
  access_type = "ObjectRead"
  versioning  = "Enabled"
}
```

## Validation Rules

- **Bucket Name**: Must be 1-63 characters, lowercase alphanumeric with hyphens, cannot start/end with hyphen
- **Compartment OCID**: Must be in valid OCID format
- **Retention Rule time_unit**: Must be either "DAYS" or "YEARS" (case-insensitive)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| oci | ~> 7.27.0 |

## Notes

- The namespace is automatically fetched using a data source if not explicitly provided
- Retention rules are optional and can be configured as a list for multiple rules
- All optional bucket settings have sensible defaults
- The module uses locals for computed values to improve readability

## License

This module is provided as-is for use in your infrastructure projects.

