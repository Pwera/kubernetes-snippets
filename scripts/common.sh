#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

# Variable Declaration

# DNS Setting
if [ ! -d /etc/systemd/resolved.conf.d ]; then
	sudo mkdir /etc/systemd/resolved.conf.d/
fi
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

sudo systemctl restart systemd-resolved

# disable swap
sudo swapoff -a

# keeps the swap off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y
# Install CRI-O Runtime

VERSION="$(echo ${KUBERNETES_VERSION} | grep -oE '[0-9]+\.[0-9]+')"
export VERSION=$VERSION

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

sudo apt-get update


if ! ls /vagrant/backup/archives/crio/cri-o*.deb 1>/dev/null 2>&1; then
  sudo mkdir /vagrant/backup/archives/crio
  echo "No cri-o packages in cache - downloading"
  sudo apt-get download cri-o cri-o-runc conmon containers-common
  sudo cp cri-o* /vagrant/backup/archives/crio/
  sudo cp conmon* /vagrant/backup/archives/crio/
  sudo cp containers-common* /vagrant/backup/archives/crio/
else
  sudo cp /vagrant/backup/archives  /var/cache/apt/archives -R
  sudo ls -lha /var/cache/apt/archives
fi
echo "Installing cri-o packages from cache"
sudo dpkg -i /vagrant/backup/archives/crio/*.deb

cat >> /etc/default/crio << EOF
${ENVIRONMENT}
EOF
sudo systemctl daemon-reload
sudo systemctl enable crio --now

echo "CRI runtime installed susccessfully"

if ! ls /vagrant/backup/archives/transport-ca/apt-transport-https*.deb 1>/dev/null 2>&1; then
  sudo mkdir /vagrant/backup/archives/transport-ca
  echo "No [apt-transport-https ca-certificates curl] packages in cache - downloading"
  sudo apt-get download apt-transport-https ca-certificates curl libcurl4
  sudo cp apt-transport* /vagrant/backup/archives/transport-ca/
  sudo cp ca-certificates* /vagrant/backup/archives/transport-ca/
  sudo cp curl* /vagrant/backup/archives/transport-ca/
  sudo cp libcurl* /vagrant/backup/archives/transport-ca/
fi
echo "Installing apt-transport-https ca-certificates curl packages from cache"
sudo dpkg -i /vagrant/backup/archives/transport-ca/*.deb

sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"

if [ ! -f "/vagrant/backup/jq" ]; then
  sudo wget https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64
  sudo chmod +x jq-linux64
  sudo mv jq-linux64 /vagrant/backup/jq
fi
echo "/vagrant/backup/jq exists copying into /usr/local/bin"
sudo cp /vagrant/backup/jq /usr/local/bin/jq

local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF

if [ ! -f "/vagrant/backup/k9s" ]; then
  sudo wget https://github.com/derailed/k9s/releases/download/$(K9S_VERSION)/k9s_Linux_amd64.tar.gz
  sudo tar -xzf k9s_Linux_amd64.tar.gz
  sudo mv k9s /vagrant/backup/k9s
  sudo cp /vagrant/backup/k9s /usr/local/bin
fi
echo "/vagrant/backup/k9s exists copying into /usr/local/bin"
sudo cp /vagrant/backup/k9s /usr/local/bin

if [ ! -f "/vagrant/backup/termshark" ]; then
  sudo wget https://github.com/gcla/termshark/releases/download/v$(TERMSHARK_VERSION)/termshark_$(TERMSHARK_VERSION)_linux_x64.tar.gz
  sudo tar -xzf termshark_$(TERMSHARK_VERSION)_linux_x64.tar.gz --strip-components=1
  sudo mv termshark /vagrant/backup/termshark
fi
echo "/vagrant/backup/termshark exists copying into /usr/local/bin"
sudo cp /vagrant/backup/termshark /usr/local/bin


echo "alias k=kubectl" >> ~/.bashrc