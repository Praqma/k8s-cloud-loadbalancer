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
