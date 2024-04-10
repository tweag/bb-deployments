#!/usr/bin/env bash
# Deploy Buildbarn with mTLS in Kubernetes in lima VM

set -xueo pipefail

# Prepare VM configuration
limactl create template://k8s --name k8s --set 'del(.mounts)' --tty=false \
  $([ "$(uname -s)" = "Darwin" ] && { echo "--vm-type vz"; [ "$(uname -m)" = "arm64" ] && echo "--rosetta"; })
mkdir -p disks/vol{0,1,2,3}
cat >> ~/.lima/k8s/lima.yaml <<EOF
mounts:
- location: "$PWD/disks/vol0"
  mountPoint: "/mnt/fast-disks/vol0"
  writable: true
- location: "$PWD/disks/vol1"
  mountPoint: "/mnt/fast-disks/vol1"
  writable: true
- location: "$PWD/disks/vol2"
  mountPoint: "/mnt/fast-disks/vol2"
  writable: true
- location: "$PWD/disks/vol3"
  mountPoint: "/mnt/fast-disks/vol3"
  writable: true
EOF

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
