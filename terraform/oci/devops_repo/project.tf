resource "oci_devops_project" "test_project" {
    compartment_id = oci_identity_compartment.devops_repo.id
    name = "kind_repo"
    description = "project to kind cluster"
    notification_config {
        topic_id = oci_ons_notification_topic.test_notification_topic.id
    }
}

resource "oci_devops_repository" "test_repository" {
    name = "KindRepo"
    project_id = oci_devops_project.test_project.id
    repository_type = "HOSTED"
    description = "Repo kind cluster"
}