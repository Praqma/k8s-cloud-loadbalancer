Before experiment:

```
[root@lb ~]# cat /proc/sys/net/ipv4/ip_forward
0
```

```
[root@lb ~]# ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:36:27:7d brd ff:ff:ff:ff:ff:ff
    inet 10.240.0.200/24 brd 10.240.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 10.240.0.2/24 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe36:277d/64 scope link 
       valid_lft forever preferred_lft forever
[root@lb ~]# 
```


Also, HAproxy is stopped.

---------------- 

```
Notice that worker is able to reach apiserver  (.21) over 6443

[root@worker1 ~]# telnet 10.240.0.21 6443
Trying 10.240.0.21...
Connected to 10.240.0.21.
Escape character is '^]'.
^]
telnet> quit
Connection closed.
[root@worker1 ~]# 
```

----------------



Notice that worker is not able to reach 6443 on (.200) as nothing is running on it yet.

```
[root@worker1 ~]# telnet 10.240.0.200 6443
Trying 10.240.0.200...
telnet: connect to address 10.240.0.200: Connection refused
[root@worker1 ~]#
```

----------------

# START EXPERIMENT:

```
[root@lb ~]# iptables -t nat -A PREROUTING -p tcp -d 10.240.0.200 --dport 6443 -j DNAT --to-destination 10.240.0.21 
```

```
[root@lb ~]# iptables -L -t nat
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
DNAT       tcp  --  anywhere             lb.example.com       tcp dpt:sun-sr-https to:10.240.0.21

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
[root@lb ~]# 
```



Notice that the worker is still not able to reach 6443 on .200 :

```
[root@worker1 ~]# telnet 10.240.0.200 6443
Trying 10.240.0.200...
^C
[root@worker1 ~]# 
```


Enable packet forwarding on .200 .


```
[root@lb ~]# echo 1 > /proc/sys/net/ipv4/ip_forward
```

```
[root@lb ~]# cat /proc/sys/net/ipv4/ip_forward
1
[root@lb ~]# 
```


Notice that the worker is still not able to reach 6443 on .200 :

```
[root@worker1 ~]# telnet 10.240.0.200 6443
Trying 10.240.0.200...
^C
[root@worker1 ~]# 
```

Still failing!!! Aaaagggghhhh


OK. Add a MASQUERADE rule on LB:

```
[root@lb ~]# iptables -t nat -A POSTROUTING -p tcp  -j MASQUERADE
```

Then go back to worker1 and this time try again:

```
[root@worker1 ~]# telnet 10.240.0.200 6443
Trying 10.240.0.200...
Connected to 10.240.0.200.
Escape character is '^]'.
^]
telnet> quit
Connection closed.
[root@worker1 ~]# 
```

It seems promising!


-------------------------------------

# Final configuration:


## Load balancer:

HAproxy is stoppped.



## Network and iptables rules:

Since the certificate we created only considers 10.240.0.20 as valid host, and not .200, so I add a IP to LB eth0 interface.

```
[root@lb ~]# ip addr add 10.240.0.20/24 dev eth0
```

```
[root@lb ~]# cat 6443-through-iptables.sh 
#!/bin/bash
echo 1  > /proc/sys/net/ipv4/ip_forward

iptables -t nat -F

iptables -t nat -A POSTROUTING -p tcp  -j MASQUERADE
iptables -t nat -A PREROUTING -p tcp -d 10.240.0.20 --dport 6443 -j DNAT --to-destination 10.240.0.21

[root@lb ~]# 
``` 

```
[root@lb ~]# iptables -t nat -L
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
DNAT       tcp  --  anywhere             lb.example.com       tcp dpt:sun-sr-https to:10.240.0.21

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
MASQUERADE  tcp  --  anywhere             anywhere            
[root@lb ~]# 
```

## Worker configuration:

First, a test:

[root@worker1 ~]# telnet 10.240.0.20 6443
Trying 10.240.0.20...
Connected to 10.240.0.20.
Escape character is '^]'.
^]
telnet> quit
Connection closed.
[root@worker1 ~]#



Looks promising, still!


Configure kubelet and kube-proxy:

```
[root@worker1 ~]# cat /etc/systemd/system/kubelet.service 
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
# The following line has IP of controller1 and controller2.
#ExecStart=/usr/bin/kubelet   --allow-privileged=true   --api-servers=https://10.240.0.21:6443,https://10.240.0.22:6443   --cloud-provider=   --cluster-dns=10.32.0.10   --cluster-domain=cluster.local   --configure-cbr0=true   --container-runtime=docker   --docker=unix:///var/run/docker.sock   --network-plugin=kubenet   --kubeconfig=/var/lib/kubelet/kubeconfig   --reconcile-cidr=true   --serialize-image-pulls=false   --tls-cert-file=/var/lib/kubernetes/kubernetes.pem   --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem   --v=2

# The following line has cluster IP
ExecStart=/usr/bin/kubelet   --allow-privileged=true   --api-servers=https://10.240.0.20:6443   --cloud-provider=   --cluster-dns=10.32.0.10   --cluster-domain=cluster.local   --configure-cbr0=true   --container-runtime=docker   --docker=unix:///var/run/docker.sock   --network-plugin=kubenet   --kubeconfig=/var/lib/kubelet/kubeconfig   --reconcile-cidr=true   --serialize-image-pulls=false   --tls-cert-file=/var/lib/kubernetes/kubernetes.pem   --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem   --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```
[root@worker1 ~]# cat /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
# The following line has controller1 IP
ExecStart=/usr/bin/kube-proxy   --master=https://10.240.0.21:6443   --kubeconfig=/var/lib/kubelet/kubeconfig   --proxy-mode=iptables   --v=2

# THe following line has cluster IP for controllers.
ExecStart=/usr/bin/kube-proxy   --master=https://10.240.0.20:6443   --kubeconfig=/var/lib/kubelet/kubeconfig   --proxy-mode=iptables   --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
[root@worker1 ~]# 
```

# Moment of truth:

Controller1:

```
[root@controller1 ~]# kubectl get nodes
NAME                  STATUS     AGE
worker1.example.com   Ready      27d
worker2.example.com   NotReady   27d
[root@controller1 ~]# 
```


Tada! 


