#!/bin/bash

#ip link delete cni0
#systemctl restart crio
#systemctl restart kubelet

kubectl taint node master-node node-role.kubernetes.io/control-plane-

kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0" \
| kubectl apply -f -

cd /vagrant/specific-files
mkdir certs
openssl genrsa -out certs/tls.key 2048
openssl req -new -key certs/tls.key -out certs/tls.csr -subj "/CN=whoami.localhost"
openssl x509 -req -extfile <(printf "subjectAltName=DNS:whoami.localhost") -in certs/tls.csr -signkey certs/tls.key -out certs/tls.crt

kubectl create secret tls mysecret     --cert "certs/tls.crt"     --key "certs/tls.key"

kubectl apply -f traefik-gateway-api.yaml



