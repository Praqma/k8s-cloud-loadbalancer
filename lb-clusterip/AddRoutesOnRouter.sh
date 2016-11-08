#!/bin/bash

# A very raw way to add routes on the router. Need to have functonality to update any router in future.

# First extract IP addresses of worker nodes and their network and subnets and then add them to the router.
# At the moment, this is being done on my KVM host (my work comptuer), so this work computer is the router for my worker node VMs.

route add -net 10.200.0.0 netmask 255.255.255.0 gw 10.240.0.31
route add -net 10.200.1.0 netmask 255.255.255.0 gw 10.240.0.32

