#!/bin/bash
LB_NODEPORT_PATH=/root/k8s-cloud-loadbalancer/lb-nodeport
LB_NODEPORT_TOOLS=${LB_NODEPORT_PATH}/lb-nodeport.f

LB_STATE_FILE=/opt/lb-nodeport.state

if [ -f ${LB_NODEPORT_TOOLS} ] ; then
  source ${LB_NODEPORT_TOOLS}
else
  echolog "LB-nodeport.sh was not found. Exiting..."
  exit 9
fi


# We check services and compare it with our state file. If states differ, we recreate haproxy and reload.

if [ -f ${LB_STATE_FILE} ] ; then
  echolog "LB state file already exits. Lets compare that (stored state) with running state..."
  getServices > /tmp/lb-nodeport.state
  diff $LB_STATE_FILE /tmp/lb-nodeport.state
  DIFF_EXIT_CODE=$?

  if [ $DIFF_EXIT_CODE -ne 0 ] ; then
    echolog "Differences found between the state file and k8s sevices. Re-creating haproxy configuration and reloading it."
    cp /tmp/lb-nodeport.state $LB_STATE_FILE
    createLoadBalancer haproxy default
    RELOAD_HAPROXY=1
  else
    echolog "No differences found between the two states. No need to restart the service"
    RELOAD_HAPROXY=0
  fi
else
  echolog "State file does not exist. This means this is the first time it is being run on this machine! Congratulations!"
  getServices > /opt/lb-nodeport.state
  echolog "Running createLoadBalancer ..."
  createLoadBalancer haproxy default
  RELOAD_HAPROXY=1
fi

if [ $RELOAD_HAPROXY -eq 1 ]; then
  SERVICE_EXIT_STATUS=$?
  if [ $SERVICE_EXIT_STATUS -ne 0 ] ; then
    echolog "Service haproxy not running. Restarting it ..."
    systemctl restart haproxy
  fi

  sleep 3
  systemctl status haproxy --no-pager -l
fi

