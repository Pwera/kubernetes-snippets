sudo ip link delete cni0
sudo systemctl restart crio
sudo systemctl restart kubelet

mkdir certs
openssl genrsa -out certs/tls.key 2048
openssl req -new -key certs/tls.key -out certs/tls.csr -subj "/CN=whoami.localhost"
openssl x509 -req -extfile <(printf "subjectAltName=DNS:whoami.localhost") -in certs/tls.csr -signkey certs/tls.key -out certs/tls.crt

kubectl create secret tls mysecret     --cert "certs/tls.crt"     --key "certs/tls.key"

kubectl taint node master-node node-role.kubernetes.io/control-plane-

wget https://github.com/holys/redis-cli/releases/download/v0.0.2/redis-cli-v0.0.2-linux-amd64
mv redis-cli-v0.0.2-linux-amd64 redis-cli
mv redis-cli /usr/local/bin

redis-cli -h localhost -p 30000 SET key value

