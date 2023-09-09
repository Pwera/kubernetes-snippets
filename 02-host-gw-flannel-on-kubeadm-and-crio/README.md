# `flannel over host-gw`

```
`sudo cat /run/flannel/subnet.env`
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=1500
FLANNEL_IPMASQ=true
```

```
`ip route` on worker-node01
default via 10.0.2.2 dev eth0 proto dhcp src 10.0.2.15 metric 100
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.11
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100
10.0.2.2 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
10.0.2.3 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
10.244.0.0/24 via 10.0.0.10 dev eth1
10.244.1.0/24 dev cni0 proto kernel scope link src 10.244.1.1

# This one was selected
10.244.2.0/24 via 10.0.0.12 dev eth1
```


# Scenario 1.
### Call server pod (by DNS) scheduled on worker-node02 from client pod scheduled on worker-node01:

`curl server`

<img src=img/host-gw-call-by-dns.png>

```
Top left:
  Source IP: client pod ip
  Destination IP: clusterIp of server service 
Bottom left:
  Source IP: client pod ip
  Destination IP: server pod ip  
Top right:
  Source IP: client pod ip
  Destination IP: server pod ip    
```

```
host-gw adds route table entries on hosts, so that host know how to traffic container network packets.
The destination MAC of traffic destined for the Pod will be set to the MAC address of node02. 
node02 then receives the packets and knows how to proceed further. 
All of that happens on L2, no L3 routing takes place. 
No encapsulation is involved.
```
