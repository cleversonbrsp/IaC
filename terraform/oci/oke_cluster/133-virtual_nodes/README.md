# OKE Cluster with Virtual Nodes (OCI) - 192.168.x.x Networking

This Terraform project provisions an Oracle Cloud Infrastructure (OCI) OKE cluster using Virtual Nodes with VCN and subnets configured in the 192.168.0.0/18 address space.

## What it creates
- A VCN `oke-vcn-virtual-nodes` with CIDR `192.168.0.0/18`.
- Three subnets:
  - Private Nodes: `192.168.0.0/20` (no public IPs)
  - Public API: `192.168.16.0/20` (Kubernetes API endpoint)
  - Service LB: `192.168.32.0/20` (for Load Balancers and NodePorts)
- Security Lists tailored for intra-cluster comms and public access to LB ports 80/443 and NodePorts 30000-32767.
- OKE cluster (Enhanced) with OCI VCN IP Native CNI, Virtual Node Pool (3 virtual nodes).

Pod and Service CIDRs use Kubernetes defaults:
- Pods CIDR: `10.244.0.0/16`
- Services CIDR: `10.96.0.0/18`

These do not overlap with the VCN subnets and are safe to keep. Adjust if needed.

## Prerequisites
- Terraform >= 1.5
- OCI account and configured CLI credentials in `~/.oci/config`
- SSH public key for instances (path in `ssh_instances_key`)

## Variables
Defined in `variables.tf`:
- `oci_region` (string): OCI region (e.g., `sa-saopaulo-1`).
- `oci_ad` (string): Availability Domain short name (e.g., `AD-1`).
- `comp_id` (string): Compartment OCID where to create resources.
- `ssh_instances_key` (string): Path to SSH public key.
- `oci_config_profile` (string): Profile name in `~/.oci/config`.

## Example tfvars
Create `terraform.tfvars` (or copy `terraform.tfvars.example`):

```hcl
oci_region         = "sa-saopaulo-1"
oci_config_profile = "DEFAULT"
oci_ad             = "AD-1"
comp_id            = "ocid1.compartment.oc1..xxxx"
ssh_instances_key  = "~/.ssh/id_rsa.pub"
```

## Usage
```bash
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

To destroy:
```bash
terraform destroy
```

## Notes
- Networking was migrated from `10.15.0.0/18` to `192.168.0.0/18` with corresponding subnets in `network.tf`.
- The provider now reads the profile via `var.oci_config_profile` in `main.tf`.
- Remaining `10.x.x.x` ranges are for Kubernetes internal Pod/Service networks as per `oke.tf` and are intentional.
