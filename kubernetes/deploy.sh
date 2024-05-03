#!/usr/bin/env bash
# Deploy Buildbarn with mTLS in Kubernetes in lima VM

set -xueo pipefail

# Prepare VM configuration
limactl create template://k8s --name k8s --tty=false \
  --set '.provision |= . + {"mode":"system","script":"#!/bin/bash
for d in /mnt/fast-disks/vol{0,1,2,3}; do sudo mkdir -p $d; sudo mount --bind $d $d; done"}' \
  $([ "$(uname -s)" = "Darwin" ] && { echo "--vm-type vz"; [ "$(uname -m)" = "arm64" ] && echo "--rosetta"; })

# Start VM
limactl start k8s
export KUBECONFIG=~/.lima/k8s/copied-from-guest/kubeconfig.yaml

# Configure persistent volumes
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-disks
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl apply -f local-static-provisioner.yaml
# Wait for volumes to be created
while [ "$(kubectl get pv --no-headers | wc -l)" -lt 4 ]; do
    sleep 1
done

# Deploy cert-manager first to create its custom resources ahead of time
kubectl apply -f cert-manager.yaml
kubectl rollout status -f cert-manager.yaml 2>&1 | grep -Ev "no status|unable to decode" || true # rollout will fail because of unsupported resources

# Deploy everything
kubectl apply -k .

# Update CA certificate
kubectl -n buildbarn wait --for=condition=Ready certificaterequests/ca-1
kubectl -n buildbarn get certificaterequests ca-1 -o jsonpath='{.status.ca}' | base64 -d | jq --raw-input --slurp . > config/ca-cert.jsonnet

# Redeploy with new configuration and wait for everything to finish
kubectl -n buildbarn scale statefulset storage --replicas 0  # statefulset doesn't recreate pods that are already failing
kubectl apply -k .
kubectl rollout status -k . 2>&1 | grep -Ev "no status|unable to decode" || true # rollout will fail because of unsupported resources
