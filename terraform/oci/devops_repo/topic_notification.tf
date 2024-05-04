resource "oci_ons_notification_topic" "test_notification_topic" {
    #Required
    compartment_id = oci_identity_compartment.devops_repo.id
    name = "topicsp"
    description = "topic tf"
    #Optional
    #defined_tags = {"Operations.CostCenter"= "42"}
    #freeform_tags = {"Department"= "Finance"}
}