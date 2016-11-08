# NodePort Loadbalancer
## Introduction
This folder contains an example of how to update a Apache webserver to reflect services running in a Kubernetes Cluster by loadbalancing them. It will create a loadbalancer for each exposed service with endpoints.

The file tools.f contains two functions. createLoadBalancer and createServiceLB. 

createServiceLB creates the lines needed for each service. It finds the ip's and port of each node and add them to a BalancerMember for that service. It write this to a file ending with .bal. At the end of each .bal file, we add a ProxyPass and ProxyPassRevers for the service as well.

createLoadBalancer will create the outer VirtualHost part, and then including alle the .bal files in it, when loaded by Apache. It saves this in a file called kubernetes.services.conf.

If kubernetes.services.conf and all the .bal files are copied to eg /etc/httpd/conf.d and apache is reloaded, you will have a funtionel loadbalancer.

## How to use
We have created a run.sh script that shows how you can use the functions. In this example, we have an Apache running on the host machine. We call createLoadBalancer and it creates the files we need. It then copies them to /etc/httpd/conf.d/ and reloads the Apache webserver.

Then, go to localhost/balancer-manager to see your loadbalancer reflect your services in your Kubernetes cluster. As mentioned earlier, only services with endpoints and a nodeport assigned, will be processed.


So start by creating a deployment
```
kubectl run my-nginx --image=nginx --replicas=2 --port=80
```

Then expose this as a service, type=NodePort
```
kubectl expose deployment my-nginx --port=80 --type=NodePort
```

Now run ./run.sh to update your Apache LoadBalancer (for HAProxy, see bottom of this page)
```
[hoeghh@localhost nodeport-loadbalancer]$ ./run.sh 
 - Running createLoadBalancer
 - Cleaning up old files
 - Copying files
 - Restarting httpd
Redirecting to /bin/systemctl reload  httpd.service
```

Go to http://localhost/balancer-manager to see your deployment being loadbalanced.
Then curl your deployment
```
[hoeghh@localhost nodeport-loadbalancer]$ curl localhost/my-nginx
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## HAProxy
If you want to output a haproxy.conf instead, then call the createLoadbalancer with the argument 'haproxy' instead. I will later split up run.sh in an Apache and HAProxy script.


# How to create a service with Nodeport:
```
[root@controller1 ~]# kubectl get services
NAME                CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes          10.32.0.1     <none>        443/TCP   55d
network-multitool   10.32.0.41    10.240.0.3    80/TCP    19d
nginx               10.32.0.237   10.240.0.2    80/TCP    49d
[root@controller1 ~]# 

[root@controller1 ~]# kubectl delete service nginx
service "nginx" deleted


[root@controller1 ~]# kubectl get deployments
NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
network-multitool   1         1         1            0           28d
nginx               4         4         4            0           52d
[root@controller1 ~]# 

[root@controller1 ~]# kubectl expose deployment nginx --port 80 --type=NodePort
service "nginx" exposed


[root@controller1 ~]# kubectl get services
NAME                CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes          10.32.0.1    <none>        443/TCP   56d
network-multitool   10.32.0.41   10.240.0.3    80/TCP    19d
nginx               10.32.0.6    <nodes>       80/TCP    7s
[root@controller1 ~]# 

[root@controller1 ~]# kubectl describe service nginx
Name:			nginx
Namespace:		default
Labels:			run=nginx
Selector:		run=nginx
Type:			NodePort
IP:			10.32.0.6
Port:			<unset>	80/TCP
NodePort:		<unset>	32146/TCP
Endpoints:		10.200.0.44:80,10.200.0.45:80,10.200.0.46:80 + 1 more...
Session Affinity:	None
No events.

[root@controller1 ~]# 
```


# Test the load balancer:

```
[root@lb lb-nodeport]# for i in $(seq 1 100); do curl localhost; sleep 1; done
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-ssrh6
Container IP: 10.200.0.48
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-pvhuz
Container IP: 10.200.0.49
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-uhtnp
Container IP: 10.200.1.56
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-ssrh6
Container IP: 10.200.0.48
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-ssrh6
Container IP: 10.200.0.48
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-uhtnp
Container IP: 10.200.1.56
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-ssrh6
Container IP: 10.200.0.48
<H1>Praqma Network MultiTool - nginx - It Works!</H1>
Container Hostname: network-multitool-2164695616-lfc22
Container IP: 10.200.0.50

. . .
``` 


Check the stats through the HAProxy web interface: `http://10.240.0.200:1936/stats`


