# Praqma Load Balancer for Kubernetes

To use this load balancer, you need a dedicated (virtual) machine within your kubernetes cluster (infrastructure) network. Then, you copy the following files to your load balander.
* loadbalancer.sh.cidr
* loadbalancer.conf
* loadbalnacer.sh.flannel 

**Note:** If you are using CNI/CIDR networking, then just copy the first two files. If you are using flannel, then copy the bottom two files. 

Put the conf file in /opt/ and adjust it accordingly.

Put the loadbalancer.sh.<yoursetup> file in /usr/local/bin/ and rename it to loadbalancer.sh . 

Run `loadbalancer.sh show` to see the current setup.

Run `loadbalancer.sh create`to setup the load balancer. 

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
