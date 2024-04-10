#!/usr/bin/env bash
# Update downloaded files

set -uio pipefail

curl -L https://raw.githubusercontent.com/kubernetes-sigs/sig-storage-local-static-provisioner/master/deployment/kubernetes/example/default_example_provisioner_generated.yaml -o local-static-provisioner.yaml
curl -LO https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
helm template -n cert-manager -a storage.k8s.io/v1/CSIDriver https://charts.jetstack.io/charts/cert-manager-csi-driver-v0.7.1.tgz > cert-manager-csi-driver.yaml
