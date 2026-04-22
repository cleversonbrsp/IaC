"""
OCI example: no tenancy OCIDs, emails, or tags hardcoded in source.

1) Provider credentials (not set here — the OCI provider reads them automatically):
   - `pulumi config set oci:tenancyOcid ...` etc., or
   - env vars `TF_VAR_tenancy_ocid`, `TF_VAR_user_ocid`, ...
   See: https://www.pulumi.com/registry/packages/oci/installation-configuration/

2) App / resource values (namespace `iac:`):
   pulumi config set iac:compartmentId "<ocid>"
   pulumi config set iac:userName "jdoe"
   pulumi config set iac:userEmail "jdoe@example.com"
   pulumi config set iac:userDescription "Sandbox user"   # optional

   Optional JSON objects (whole value must be valid JSON):
   pulumi config set iac:freeformTags '{"Department":"Finance"}'
   pulumi config set iac:definedTags '{"Operations.CostCenter":"42"}'
"""

import pulumi
import pulumi_oci as oci

cfg = pulumi.Config("iac")

compartment_id = cfg.require("compartmentId")
user_name = cfg.require("userName")
user_email = cfg.require("userEmail")
description = cfg.get("userDescription") or "Managed by Pulumi"

freeform_tags = cfg.get_object("freeformTags")
if freeform_tags is None:
    freeform_tags = {"Department": cfg.get("department") or "Finance"}

defined_tags = cfg.get_object("definedTags")

user_args: dict = {
    "compartment_id": compartment_id,
    "name": user_name,
    "description": description,
    "email": user_email,
    "freeform_tags": freeform_tags,
}
if defined_tags:
    user_args["defined_tags"] = defined_tags

oci.identity.User("test_user", **user_args)
