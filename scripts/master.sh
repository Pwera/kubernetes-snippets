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
    if [ ! -e "/vagrant/backup/kube-flannel.yml" ]; then
      curl https://raw.githubusercontent.com/flannel-io/flannel/v${FLANNEL_VERSION}/Documentation/kube-flannel.yml -O
      cp kube-flannel.yml /vagrant/backup/kube-flannel.yml
    else
      cp /vagrant/backup/kube-flannel.yml .
    fi
    #sed -i -e 's/10.244.0.0/172.16.1.0/g'  kube-flannel.yml
    if [ "$FLANNEL_BACKEND" == "host-gw" ]; then
      sed -i -e "s/vxlan/host-gw/g" /vagrant/backup/kube-flannel.yml
      # TODO: Find general solution to put --iface=eth1
      # iface is provided because of this issue:
      # https://github.com/flannel-io/flannel/blob/master/Documentation/troubleshooting.md#vagrant
      # TODO: Fix this
      sed -i  '173i \\t\t- --iface=eth1' /vagrant/backup/kube-flannel.yml
      #export REPLACE="--iface=eth1"
      #./yq_linux_amd64 "spec.template.spec.containers[0].args[2] = env(REPLACE)" kube-flannel.yml -i
      #./yq_linux_amd64 ".spec.containers[0].args[2] = env(REPLACE)" kube-flannel.yml -i
    fi
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
EOF

#if [ ! -z "$FLANNEL_VERSION" ]
#echo "Restart flannel & bridge interfaces"
#sudo -i -u vagrant bash << EOF
#  sudo ip a
#  sudo ip link set cni0 down
#  sudo ip link set flannel.1 down
#  sudo ip link delete cni0
#  sudo ip link delete flannel.1
#  sudo systemctl restart crio
#  sudo systemctl restart kubelet
#  sudo ip a
#EOF

#fi


# Install Metrics Server
#kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

