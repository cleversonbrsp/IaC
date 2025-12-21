# Common Terraform Patterns and Templates

This directory contains shared templates and reference implementations for common Terraform patterns used across all modules in the `nvt_infra` infrastructure.

## Purpose

While Terraform requires variables to be defined in each module that uses them, we maintain consistency and reduce duplication by:

1. **Standardizing variable definitions** - Common variables use identical structure across modules
2. **Using locals blocks** - Consolidate repeated `coalesce()` patterns within each module
3. **Template files** - Reference implementations for common configurations

## Directory Structure

```
_common/
├── README.md                    # This file
├── main.tf.template            # Standard provider configuration
├── variables-common.tf         # Common variable definitions (reference)
└── locals.tf.template         # Locals block template for coalesce patterns
```

## Common Patterns

### 1. Provider Configuration (`main.tf.template`)

All modules use the same provider configuration. Copy this to your module's `main.tf`:

```hcl
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~>7.29.0"
    }
  }
}

provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.oci_region
}
```

**Benefits:**
- Consistent provider version across all modules
- Single source of truth for provider configuration

### 2. Common Variables (`variables-common.tf`)

These variables should be defined in every module's `variables.tf`:

- `oci_region` - OCI region identifier
- `oci_config_profile` - OCI config profile name
- `compartment_id` - Compartment OCID
- `comp_id` - Legacy compartment variable (for compatibility)
- `common_tags` - Tags applied to all resources
- `defined_tags` - Module-specific tag overrides

**Why keep variables in each module?**
Terraform requires variables to be defined in the module scope where they're used. While we can't share variable definitions directly, using consistent structure ensures:
- Predictable module interfaces
- Easy to understand and maintain
- Consistent validation rules

### 3. Locals Block (`locals.tf.template`)

Each module should include a `locals.tf` file that consolidates common patterns:

```hcl
locals {
  # Resolve compartment ID (supports both compartment_id and legacy comp_id)
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  
  # Resolve tags (common_tags take precedence, defined_tags is override)
  defined_tags = coalesce(var.common_tags.defined_tags, var.defined_tags)
}
```

**Usage in resources:**
```hcl
resource "oci_core_instance" "example" {
  compartment_id = local.compartment_id  # Instead of: coalesce(var.comp_id, var.compartment_id)
  defined_tags   = local.defined_tags    # Instead of: coalesce(var.common_tags.defined_tags, var.defined_tags)
  # ...
}
```

**Benefits:**
- Reduces repetition from 22+ `coalesce()` calls to 2 local references
- Single source of truth for compartment and tags resolution
- Easier to modify logic in one place if patterns change
- Cleaner, more readable resource definitions

## Refactoring Impact

### Before Refactoring

**Repeated patterns:**
- `coalesce(var.comp_id, var.compartment_id)` - 22 occurrences
- `coalesce(var.common_tags.defined_tags, var.defined_tags)` - 20 occurrences
- Provider configuration - 5 identical blocks
- Common variable definitions - 5 sets of identical variables

**Maintenance burden:**
- Changes to compartment resolution logic required updates in 22+ places
- Tag resolution changes required updates in 20+ places
- Easy to miss updates when patterns change
- Inconsistent patterns across modules

### After Refactoring

**Consolidated patterns:**
- `local.compartment_id` - Single definition per module, used throughout
- `local.defined_tags` - Single definition per module, used throughout
- Provider configuration - Template maintained in `_common/`
- Common variables - Template maintained in `_common/`

**Maintenance improvements:**
- Changes to compartment/tag logic require updates in 1 place per module
- Easier to understand intent (local.compartment_id vs long coalesce chain)
- Consistent patterns across all modules
- Template files provide reference for new modules

## Best Practices

1. **Always use locals for repeated coalesce patterns** - Don't repeat `coalesce()` calls throughout resources
2. **Follow the template structure** - When creating new modules, start from these templates
3. **Keep variable definitions consistent** - Use the same structure and validation rules
4. **Update templates when patterns evolve** - If common patterns change, update both templates and modules

## Module-Specific Variables

While common variables are standardized, each module will have additional variables specific to its resources:

- **network/** - VCN CIDR blocks, subnet configurations, security list rules
- **instance/** - Instance shapes, images, SSH keys, availability domains
- **cluster-k8s/** - Kubernetes versions, node pool configurations, CNI settings
- **dbsystem/** - Database versions, instance counts, backup policies
- **bucket/** - Bucket configurations, retention rules, access types

These module-specific variables should follow the same naming conventions and documentation standards as common variables.

