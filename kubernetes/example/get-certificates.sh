#!/usr/bin/env bash
# Generate certificates for Bazel with cert-manager

set -xueo pipefail

export KUBECONFIG=~/.lima/k8s/copied-from-guest/kubeconfig.yaml

cmctl create certificaterequest -n buildbarn client --from-certificate-file cert-template.yaml --fetch-certificate
kubectl -n buildbarn get certificaterequests ca-1 -o jsonpath='{.status.ca}' | base64 -d > ca.crt
openssl pkcs8 -topk8 -nocrypt -in client.key -out client.pem
