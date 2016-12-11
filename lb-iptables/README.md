Run some docker containers on the host and then run `lb.sh` . There is no need to expose any ports of the docker containers. Though you are encourged to use `-P` in the docker run command to expose the container ports on any randomly chosen ports on the host. These ports do not matter at all and the load balancer does not account for them. The magic is in the iptables rules, not the exposed ports of the containers.

Enjoy! 
