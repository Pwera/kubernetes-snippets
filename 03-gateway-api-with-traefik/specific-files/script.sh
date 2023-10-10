sudo ip link delete cni0
sudo systemctl restart crio
sudo systemctl restart kubelet

mkdir certs
openssl genrsa -out certs/tls.key 2048
openssl req -new -key certs/tls.key -out certs/tls.csr -subj "/CN=whoami.localhost"
openssl x509 -req -extfile <(printf "subjectAltName=DNS:whoami.localhost") -in certs/tls.csr -signkey certs/tls.key -out certs/tls.crt

openssl genrsa -out certs/tls.key 2048
openssl req -new -key certs/tls.key -out cesrts/tls.csr -subj "/CN=katacoda.com"
openssl x509 -req -extfile <(printf "subjectAltName=DNS:webhook-server.production.svc,DNS:*.2887302149-30001-host12nc.environments.katacoda.com") -in certs/tls.csr -signkey certs/tls.key -out certs/tls.crt

kubectl create secret tls mysecret     --cert "certs/tls.crt"     --key "certs/tls.key"

kubectl taint node master-node node-role.kubernetes.io/control-plane-