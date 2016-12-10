#!/bin/bash
CIP=$1
CNAME=$2
iptables -t nat -D DOCKER ! -i docker0 -p tcp -m tcp \
  -m comment --comment "PRAQMA-${CNAME}" \
  -m multiport --dports 80,443 \
  -j DNAT --to-destination $CIP

