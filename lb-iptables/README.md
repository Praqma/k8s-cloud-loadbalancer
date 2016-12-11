Run some docker containers on the host and then run `lb.sh` . There is no need to expose any ports of the docker containers. Though you are encourged to use `-P` in the docker run command to expose the container ports on any randomly chosen ports on the host. These ports do not matter at all and the load balancer does not account for them. The magic is in the iptables rules, not the exposed ports of the containers.

When `lb.sh` finishes running, it will setup additional IP addresses on the docker host, and will setup necessary forwarding rules. These rules can be listed using `sudo iptables-save | grep PRAQMA` . You will see which IP is handling which container , by looking at the rules. This will be made more user friendly in the coming days.

This is kind of version 1. In coming days , I will further simplify the logic and will add capability to update DNS too. 

Enjoy! 
