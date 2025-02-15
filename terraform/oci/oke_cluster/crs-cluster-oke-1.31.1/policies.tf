resource "oci_identity_dynamic_group" "oke_dynamic_group" {

    compartment_id = var.comp_id
    description = "OKE Dynamic Group"
    matching_rule = var.dynamic_group_matching_rule
    name = "oke-dynamic-group"

    # defined_tags = {"Operations.CostCenter"= "42"}
    # freeform_tags = {"Department"= "Finance"}
}