#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -euxo pipefail

NODENAME=$(hostname -s)

sudo kubeadm config images pull
#--rootfs string

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

kubeadm token create --print-join-command > $config_path/join.sh

# Install Flannel Network Plugin
if [ -z "$FLANNEL_VERSION" ]
then
    echo "Flannel not defined"
else
    echo "Flannel defined: $FLANNEL_VERSION"
    #curl https://raw.githubusercontent.com/flannel-io/flannel/v${FLANNEL_VERSION}/Documentation/kube-flannel.yml -O
    #sed -i -e 's/10.244.0.0/172.16.1.0/g'  kube-flannel.yml
    cp /vagrant/backup/kube-flannel.yml .
    kubectl apply -f kube-flannel.yml
fi

# Install Calico Network Plugin
if [ -z "$CALICO_VERSION" ]
then
    echo "Calico not defined"
else
    echo "Calico defined: $CALICO_VERSION"
    curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O
    kubectl apply -f calico.yaml
fi

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config

echo "Network interfaces"
sudo ip a
sudo ip link set cni0 down
sudo ip link set flannel.1 down
sudo ip link delete cni0
sudo ip link delete flannel.1
sudo systemctl restart crio
sudo systemctl restart kubelet
echo "Network interfaces"
sudo ip a
EOF

# Install Metrics Server

#kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml
