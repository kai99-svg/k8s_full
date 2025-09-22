#!/bin/bash
set -o xtrace
mkdir -p /etc/nodeadm
cat <<EOC > /etc/nodeadm/config.yaml
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${cluster_name}
    apiServerEndpoint: "${api_server_endpoint}"
    certificateAuthority: |
%{ for line in split("\n", certificate_authority) ~}
      ${line}
%{ endfor ~}
    cidr: "172.20.0.0/16"
EOC

sudo /usr/bin/nodeadm init --config-source file:///etc/nodeadm/config.yaml