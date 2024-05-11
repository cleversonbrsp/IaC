### Local Acces
You must have downloaded and installed OCI CLI version 2.24.0 (or later) and configured it for use. If your version of the OCI CLI is earlier than version 2.24.0, download and install a newer version from here. If you are not sure of the version of the OCI CLI you currently have installed, check with this command:

oci -v

### Create a directory to contain the kubeconfig file.
mkdir -p $HOME/.kube

### To access the kubeconfig for your cluster via the VCN-Native public endpoint, copy the following command (example):
oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.sa-saopaulo-1.xyz.... --file $HOME/.kube/config --region sa-saopaulo-1 --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT (or --kube-endpoint PRIVATE_ENDPOINT)

### To set your KUBECONFIG environment variable to the file for this cluster, use:
export KUBECONFIG=$HOME/.kube/config

