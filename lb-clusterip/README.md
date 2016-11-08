# Praqma Load Balancer for Kubernetes

To use this load balancer, you need a dedicated (virtual) machine within your kubernetes cluster (infrastructure) network. Then, you need kube-proxy running on the LB machine, because the load balancer will use kube-proxy to interact with kubernetes master. Though kube-proxy will need certain certificates you are/will be using in your kubernetes cluster.


If you do not want to use kube-proxy, then you can (manually) setup a SSH tunnel to one of your controller nodes, forwarding port 8080 from controller node to the loadbalancer. You can use autossh to setup a forwarder, so the loadbalancer script always has a SSH based connection to the controller node.

```
$ ssh -L -N 8080:localhost:8080 user@controller1 
``` 

_Using kube-proxy is easier and preferred **;)**_


Verify that you can interact with your kubernetes controller nodes using kubectl commands runnin on this load balancer machine.  

```
$ kubectl get nodes

$ kubectl get cs
```


Next, pull the praqma/k8s-cloud-loadbalancer repo to a directory on your load balancer machine, (which you probably did already), and copy the following files to your load balander.

* loadbalancer.conf
* loadbalancer.sh.cidr
* loadbalnacer.sh.flannel 

**Note:** If you are using CNI/CIDR networking, then copy the loadbalance.conf and loadbalancer.sh.cidr files. If you are using flannel, then copy the loadbalancer.conf and loadbalancer.sh.flannel files.  

* Put the conf file in /usr/local/etc and adjust it accordingly.
* Put the loadbalancer.sh.<YourNetworkSetup> file in /usr/local/bin/ and rename it to loadbalancer.sh . 
* Run `loadbalancer.sh show` to see the current setup.
* Run `loadbalancer.sh create`to setup the load balancer. 

Make sure tha the services in the kubernetes cluster have an external IP address assigned to them. If not, select an IP address from the pool of available IPs, shown when you run loadbalancer.sh in the `show` mode. There is an issue/bug against this and will be fixed soon. [https://github.com/Praqma/LearnKubernetes/issues/5](https://github.com/Praqma/LearnKubernetes/issues/5) 


**Notes:**
* The haproxy configuration EXPECTS a node or range of nodes in the bind directive. So mentioning node(s) in bind directive is mandatory.
* The server directive doesn't need to have ports mentioned. If skipped, the same ports the client connects on is (are) used. 
```
listen default-nginx-80-443
        bind 10.240.0.2:80,10.240.0.2:443
        server pod-1 10.200.1.25 check
        server pod-2 10.200.1.26 check
        server pod-3 10.200.1.27 check
        server pod-4 10.200.1.28 check
```

Have fun!

--------

# Load balancing Kubernetes controller nodes behind a load balancer.

We have multiple controller (aka. master) nodes, with a hope to have HA. The API service is available on 8080 and also on 6443. 

We have success in setting up a proxy forwarder using 8080. So now when we talk to the lb from anywhere on the network, on port 8080, we get to api server and extract information. Here is how:

```
listen kubernetes-8080
   bind 10.240.0.200:8080
   server controller1 10.240.0.21:8080 check
   server controller2 10.240.0.22:8080 check
``` 

There are few assumptions about the code shown above:
* The loadbalancer VM's primary (infrastructure) IP is 10.240.0.200 . 
* The Kubernetes controller nodes are on IP addresses 10.240.0.21 and 10.240.0.22 .

We decided to use the primary IP of the loadbalancer and not use a secondary IP for the kubernetes service, because the primary purpose of this load balancer is to support this k8s cluster. So forwarding port 8080 traffic using the LB's primary IP to backend controller nodes saves one IP (in tight network situations), and is super easy, as it does not involve any certificates, etc. This also means that is is SUPER INSECURE!!! So we better block access to 10.240.0.200:8080 on the router/firewall so there is no unwanted access to Kuberentes API server.


------


# Load balancing kubernetes service by exposeing the kubernetes service using an external IP:
Another way we tried was based on the fact that as soon as we setup first controller node, there is a service called "kubernetes", and it listens on 443. What if we could assign it an external IP and then make the worker nodes' service configurations to look up to this external IP instead! This service already has two EndPoints , which are the IP address of the controller nodes. It will be very convenient!

```
[root@controller1 ~]# kubectl get services
NAME                CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes          10.32.0.1     <none>        443/TCP   28d
nginx               10.32.0.237   10.240.0.2    80/TCP    22d
```

```
[root@controller1 ~]# kubectl describe service kubernetes 
Name:			kubernetes
Namespace:		default
Labels:			component=apiserver
			provider=kubernetes
Selector:		<none>
Type:			ClusterIP
IP:			10.32.0.1
Port:			https	443/TCP
Endpoints:		10.240.0.21:6443,10.240.0.22:6443
Session Affinity:	ClientIP
No events.

[root@controller1 ~]# 
```

We tried:

```
[root@controller1 ~]# kubectl expose service kubernetes --external-ip=10.240.0.20 --port=433 --name=kubernetes-443
error: couldn't retrieve selectors via --selector flag or introspection: the service has no pod selector set
See 'kubectl expose -h' for help and examples.
[root@controller1 ~]# 
```

Unfortunately, it doesn't work, because this is a special service and it does not have pods as it's endpoints. So we need to have haproxy setup port 6443, so the worker nodes can then contact a single IP address instead of contacting just one controller.


I also have an idea of just DNAT port 6443 from the load balancer to the controller nodes, but that would involve IPtables, and I do not want to make a mess in this howto.



**Note:**

* The proxy can serve two ways. i.e. It can proxy for backend services, and at the same time, it can serve as a proxy for some special outside service.
* Need to have a default proxy in place, as we want to use the same proxy for providing HA to Kubernetes control plane. And for that matter, Proxy must be the first thing which comes online. 

