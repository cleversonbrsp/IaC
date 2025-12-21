# ========================================
# Local Values for Common Patterns
# ========================================
# Consolidates repeated coalesce() patterns to reduce duplication
# and improve maintainability

locals {
  # Resolve compartment ID (supports both compartment_id and legacy comp_id)
  compartment_id = coalesce(var.comp_id, var.compartment_id)
  
  # Resolve tags (common_tags take precedence, defined_tags is override)
  defined_tags = coalesce(var.common_tags.defined_tags, var.defined_tags)
}

