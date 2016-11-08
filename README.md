# Kubernetes cloud loadbalancer
The Load Balancer is now a separate repository instead of being a sub directory inside praqma/LearnKubernetes

This loadbalancer will mimic the functionality given by cloud loadbalancers from eg. Google and AWS in the way that it watches the apiServer for events, and automaticly reconfigure when needed. 

There are two versions of load balancer in this repo. 

* The original version we worked on to replicate the functionality of what a *Service* does inside Kubernetes. This is a bit complicated in it's functionality ,becasue it uses the *ExternalIP* in *Service* declaration.
* The simpler version which uses *NoePort* . 

## Pros and cons of either approach:
* The problem with nodeport is that you are limited by the ports the kubernetes cluster has to offer. e.g. You can expose a web server, for example *Apache*, on port 80. What if you have another server running on the cluster which is exposed on port 80 as well, such as *Nginx*? With Nodeport, you can expose it through another port such as 81, or 8081, or anything else, but not port 80. This is because the IP address of the backend servers (the worker nodes) remain the same. 
* With the other type of load balancer, such as ClusterIP, multiple services can be using the same port, but on different cluster IP addresses. This makes the cluster IP mechanism much more versatile. Multiple IP addresses can be virtually mapped to the load balancer, using IProute2 utilities.


## Architechture
This loadbalancer consists of two main components, apiReader and loadbalancer.

### apiReader
The apiReader acts as an easy way to connect to the Kubernetes api server. 

### Loadbalancer
The Loadbalancer is the main process. It uses HAProxy to proxy services from outside the cluster. It configures HAProxy based on the data it gets from apiReader. 

## Getting started

## Roadmap
