# ========================================
# Provider Configuration
# ========================================
variable "oci_region" {
  description = "OCI region identifier (e.g., sa-saopaulo-1)"
  type        = string
  validation {
    condition     = var.oci_region != ""
    error_message = "OCI region must be provided."
  }
}

variable "oci_config_profile" {
  description = "OCI config profile name from ~/.oci/config"
  type        = string
  default     = "DEFAULT"
}

# ========================================
# Compartment Configuration
# ========================================
variable "compartment_id" {
  description = "OCID of the compartment where resources will be created"
  type        = string
  validation {
    condition     = can(regex("^ocid1.compartment.oc1", var.compartment_id)) || var.compartment_id == ""
    error_message = "Compartment OCID must be a valid OCID format or empty string."
  }
}

variable "comp_id" {
  description = "Legacy/compatible variable name for compartment OCID"
  type        = string
  default     = ""
}

# ========================================
# Network Configuration
# ========================================
variable "vcn_id" {
  description = "OCID of the VCN where the OKE cluster will be created"
  type        = string
}

variable "oke_api_endpoint_subnet_id" {
  description = "OCID of the OKE API endpoint subnet"
  type        = string
}

variable "oke_node_subnet_id" {
  description = "OCID of the OKE node subnet"
  type        = string
}

variable "oke_lb_subnet_id" {
  description = "OCID of the OKE load balancer subnet"
  type        = string
}

# ========================================
# Cluster Configuration
# ========================================
variable "cluster_name" {
  description = "Name of the OKE cluster"
  type        = string
  default     = "nvt-oke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "v1.34.1"
}

variable "cluster_type" {
  description = "Type of OKE cluster (BASIC_CLUSTER or ENHANCED_CLUSTER)"
  type        = string
  default     = "ENHANCED_CLUSTER"
}

variable "pods_cidr" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.96.0.0/16"
}

variable "cni_type" {
  description = "CNI type for the cluster (FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE)"
  type        = string
  default     = "FLANNEL_OVERLAY"
}

variable "is_public_ip_enabled" {
  description = "Whether to enable public IP for the API endpoint"
  type        = bool
  default     = true
}

# ========================================
# Node Pool Configuration
# ========================================
variable "node_pool_name" {
  description = "Name of the node pool"
  type        = string
  default     = "pool01"
}

variable "node_pool_size" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "node_shape" {
  description = "Shape for the node pool instances"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_shape_config" {
  description = "Shape configuration for nodes (OCPUs and memory)"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 1
    memory_in_gbs = 8
  }
}

variable "node_kubernetes_version" {
  description = "Kubernetes version for the node pool"
  type        = string
  default     = "v1.34.1"
}

variable "image_id" {
  description = "OCID of the image to use for node pool instances"
  type        = string
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 31
}

# ========================================
# Tags Configuration
# ========================================
variable "defined_tags" {
  description = "Defined tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type = object({
    defined_tags = map(string)
  })
  default = {
    defined_tags = {}
  }
}

