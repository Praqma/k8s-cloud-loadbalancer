# This Dockerfile creates a small DNS server using BIND.
# References:  
# * https://hub.docker.com/r/sameersbn/bind/~/dockerfile/ 
# * https://www.damagehead.com/blog/2015/04/28/deploying-a-dns-server-using-docker/
# * Docker-Compose: https://gist.github.com/sameersbn/ea4692d9a8ee7accd6b3


FROM centos:7
MAINTAINER kaz@praqma.net

# It is important to set these environment variables as the entrypoint.sh script uses them.
ENV  BIND_USER=named

# This DNS server (BIND) will already be in a chroot envrironment (so to speak) .i.e. a container. 
# So no need to put it in yet another chroot environment. So I don't need to use bind-chroot

## We should not use yum update, as we should trust the upstream vendor (docker repo) to be fairly updated.
## RUN yum -y update 


# Just install the necessary software
RUN yum -y install which bind bind-utils


EXPOSE 53/tcp 53/udp 

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

COPY named.conf	  /etc/
COPY acme.zone /var/named/
RUN chown named:named /var/named/acme.zone

# ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/sbin/entrypoint.sh",  "/usr/sbin/named"]


# Build Instructions:
# -------------------
# docker build -t acme/dns .

# Usage:
# ------
# The following binds to all interfaces on the host:
# docker run  -p 53:53/tcp -p 53:53/udp  -d acme/dns 

# The following binds to only docker0 insterface, so it does not mess up with other DNS services on host.
# docker run  --dns=127.0.0.1  -p 172.17.0.1:53:53/tcp -p 172.17.0.1:53:53/udp  -d acme/dns 

# Note: Passing the --dns=127.0.0.1 ensures that the /etc/resolv.conf file has only this entry. Otherwise it will be obtained from the host,
# which is not desired for a DNS cotainer.

