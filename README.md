# Kubernetes cloud loadbalancer
The Load Balancer is now a separate repository instead of being a sub directory inside praqma/LearnKubernetes

This loadbalancer will mimic the functionality given by cloud loadbalancers from eg. Google and AWS in the way that it watches the apiServer for events, and automaticly reconfigure when needed. I reacts on service exposed as loadbalancer, and should, when done, update the service with an external ip.

## Architechture
This loadbalancer consists of two main components, apiReader and loadbalancer.

### apiReader
The apiReader acts as an easy way to connect to the Kubernetes apiReader. 

### Loadbalancer
The Loadbalancer is the main process. It uses HAProxy to proxy services from outside the cluster.

## Getting started

## Roadmap
