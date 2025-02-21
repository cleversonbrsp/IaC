resource "oci_identity_dynamic_group" "oke_dynamic_group" {
  name           = "dynamic-group-policies"
  compartment_id = var.comp_id
  description    = "OKE Dynamic Group"
  
  matching_rule  = "ALL {instance.compartment.id = 'ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq', resource.type = 'NodePool'}"
  }

resource "oci_identity_policy" "oke_node_pool_policy" {
  compartment_id = var.comp_id
  name           = "oke-dynamic-group-policies"
  description    = "Manage OKE Node Pools Policy"
  statements = [
    "Allow dynamic-group dynamic-group-policies to manage all-resources in tenancy"
    #"Allow dynamic-group dynamic-group-policies to manage cluster-node-pools in compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq",
    #"Allow dynamic-group dynamic-group-policies to manage instance-family in compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq",
    #"Allow dynamic-group dynamic-group-policies to use subnets in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq",
    #"Allow dynamic-group dynamic-group-policies to read virtual-network-family in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq",
    #"Allow dynamic-group dynamic-group-policies to use vnics in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq",
    #"Allow dynamic-group dynamic-group-policies to inspect compartments in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq",
  ]
}

# Allow dynamic-group dynamic-group-policies to manage all-resources in compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow service oke to read app-catalog-listing in compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow dynamic-group dynamic-group-policies to read secret-bundles in compartment VaultCompartment where target.secret.id = '<OCID for OCIR token secret>' 
# Allow dynamic-group dynamic-group-policies to use dynamic-groups in tenancy

# Allow dynamic-group dynamic-group-policies to manage cluster-node-pools in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow dynamic-group dynamic-group-policies to manage instance-family in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow dynamic-group dynamic-group-policies to use subnets in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow dynamic-group dynamic-group-policies to read virtual-network-family in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow dynamic-group dynamic-group-policies to use vnics in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow dynamic-group dynamic-group-policies to inspect compartments in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# allow dynamic-group cluster-autoscaler to inspect cluster-node-pools in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# allow dynamic-group cluster-autoscaler to manage cluster-node-pools in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq
# Allow dynamic-group dynamic-group-policies to manage cluster-node-pools in compartment id compartment ocid1.compartment.oc1..aaaaaaaanoa43uhf7bh3uz64uztwu3tjqm55ew44q72t3sdiko2272tqnxbq