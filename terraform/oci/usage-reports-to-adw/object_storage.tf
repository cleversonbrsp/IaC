// Object Storage related inputs are not directly provisioned by upstream; usage reports bucket is in Oracle tenancy.
// The upstream stack defines policies to allow reading usage-report tenancy objects via IAM policy statements.
// Therefore, bucket creation is not required here. This file is intentionally left minimal.

// No resources to create. Policies handled in iam_policies.tf

