# `flannel over vxlan`

The VXLAN tunneling protocol that encapsulates Layer 2 Ethernet frames in Layer 4 UDP packets.

```
master node ip  10.0.0.10
FLANNEL_NETWORK 10.244.0.0/16
FLANNEL_SUBNET  10.244.0.1/24
pod in master   10.244.0.13
ip route >
10.244.0.0/24 dev cni0 proto kernel scope link src 10.244.0.1
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink
arp -a >
? (10.244.0.13) at de:15:dd:3f:0f:0f [ether] on cni0
worker-node01 (10.0.0.11) at 08:00:27:85:9c:2f [ether] on eth1
_gateway (10.0.2.2) at 52:54:00:12:35:02 [ether] on eth0
? (10.244.1.0) at b6:ff:a3:f1:ef:bd [ether] PERM on flannel.1
? (10.244.0.14) at 26:56:4f:02:e8:52 [ether] on cni0
user (10.0.0.1) at 0a:00:27:00:00:01 [ether] on eth1
? (10.0.2.3) at 52:54:00:12:35:03 [ether] on eth0

worker node ip  10.0.0.11
FLANNEL_NETWORK 10.244.0.0/16
FLANNEL_SUBNET  10.244.1.1/24
pod in worker   10.244.1.21
ip route >
10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink
10.244.1.0/24 dev cni0 proto kernel scope link src 10.244.1.1
arp -a >
? (10.244.0.0) at 12:d4:20:e6:17:2d [ether] PERM on flannel.1
? (10.0.2.3) at 52:54:00:12:35:03 [ether] on eth0
_gateway (10.0.2.2) at 52:54:00:12:35:02 [ether] on eth0
? (10.244.1.21) at c2:cd:62:12:7b:7f [ether] on cni0
? (10.244.1.20) at 5e:76:71:67:cb:a3 [ether] on cni0
master-node (10.0.0.10) at 08:00:27:02:62:2c [ether] on eth1
```

```
sudo tshark -V --color -i eth1 -d udp.port=8472,vxlan -f "port 8472"
sudo termshark -i eth1 -d udp.port=8472,vxlan
sudo termshark -i flannel.1 -d udp.port=8472,vxlan
```

<img src=img/VXLAN-frame.jpg>

# Scenario 1.
### Call pod (by IP) scheduled on master node from worker node:

`curl 10.244.0.13`

![](img/call-by-ip.gif)

# Scenario 2.
### Call pod (by DNS) scheduled on master node from worker node:

`curl test`

![](img/call-by-dns.gif)


# Scenario 3.
### Calling pod on any node through NodePort

`vagrant@worker-node01:~$ curl localhost:30002`

![](img/call-by-dns.gif)


Credit: Original Vagrant script comes from https://github.com/techiescamp/vagrant-kubeadm-kubernetes