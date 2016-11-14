#!/bin/bash
LB_NODEPORT_TOOLS=/root/k8s-cloud-loadbalancer/lb-nodeport/lb-nodeport.f

LB_STATE_FILE=/opt/lb-nodeport.state

if [ -f ${LB_NODEPORT_TOOLS} ] ; then
  source ${LB_NODEPORT_TOOLS}
else
  echo "LB-nodeport.sh was not found. Exiting..."
  exit 9
fi


# We check services and compare it with our state file. If states differ, we recreate haproxy and reload.

getServices > /tmp/lb-nodeport.state

if [ -f ${LB_STATE_FILE} ] ; then
  echo "LB state file already exits. Lets compare..."
  DIFF_EXIT_CODE=$(diff $LB_STATE_FILE /tmp/lb-nodeport.state)

  cp /tmp/lb-nodeport.state $LB_STATE_FILE
  if [ $DIFF_EXIT_CODE -ne 0 ]; then
    echo "Differences found between the state file and k8s sevices. Re-creating haproxy configuration and reloading it."
    createLoadBalancer haproxy default
    RELOAD_HAPROXY=1

  else
    echo "Differences not found . Not need to restart the service"
    RELOAD_HAPROXY=0
  fi
else
  # state file does not exist. This means this is the first time it is being run on this machine! Congratulations!
  echo " - Running createLoadBalancer ..."
  createLoadBalancer haproxy default
  RELOAD_HAPROXY=1
fi



if [ $RELOAD_HAPROXY -eq 1 ]; then
  systemctl reload haproxy
  sleep 3
  systemctl status haproxy --no-pager -l
fi
