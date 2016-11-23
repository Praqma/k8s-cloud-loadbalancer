#!/bin/bash

SCRIPT_PATH=$(dirname $0)
pushd $(pwd)
cd $SCRIPT_PATH



LB_NODEPORT_PATH=${SCRIPT_PATH}

LB_NODEPORT_TOOLS=${LB_NODEPORT_PATH}/lb-nodeport.f

LB_STATE_FILE=/tmp/lb-nodeport.state

# Location of haproxy binary:
HAPROXY=/usr/sbin/haproxy


if [ -f ${LB_NODEPORT_TOOLS} ] ; then
  source ${LB_NODEPORT_TOOLS}
else
  echolog "LB-nodeport.f was not found. Exiting..."
  popd
  exit 9
fi


# We check services and compare it with our state file. If states differ, we recreate haproxy and reload.

if [ -f ${LB_STATE_FILE} ] ; then
  echolog "LB state file already exits (${LB_STATE_FILE}). Lets compare that (stored state) with running state..."
  getServices > ${LB_STATE_FILE}.running
  diff $LB_STATE_FILE ${LB_STATE_FILE}.running
  DIFF_EXIT_CODE=$?

  if [ $DIFF_EXIT_CODE -ne 0 ] ; then
    echolog "Differences found between the state file and k8s sevices. Re-creating haproxy configuration and reloading it."
    cp ${LB_STATE_FILE}.running $LB_STATE_FILE
    createLoadBalancer haproxy default
    RELOAD_HAPROXY=1
  else
    echolog "No differences found between the two states. No need to restart the service."
    RELOAD_HAPROXY=0
  fi
else
  echolog "State file does not exist (${LB_STATE_FILE}). This means this is the first time it is being run on this machine! Congratulations!"
  getServices > ${LB_STATE_FILE}
  echolog "Running createLoadBalancer ..."
  createLoadBalancer haproxy default
  RELOAD_HAPROXY=1
fi



# echo "HAPROXY binary found at: $HAPROXY"
# echo "RELOAD direction is: $RELOAD_HAPROXY"

echo "HAproxy ($HAPROXY) service is managed by: $SERVICE_MANAGER"

if [ $RELOAD_HAPROXY -eq 1 ] && [ "${SERVICE_MANAGER}" == "systemd" ] ; then
  systemctl reload haproxy
  SERVICE_EXIT_STATUS=$?
  if [ $SERVICE_EXIT_STATUS -ne 0 ] && [ "${SERVICE_MANAGER}" == "systemd" ] ; then
    echolog "Service haproxy not running. Restarting it ..."
    systemctl restart haproxy
  fi
  sleep 2
  systemctl status haproxy --no-pager -l
fi


if [ $RELOAD_HAPROXY -eq 1 ] && [ "${SERVICE_MANAGER}" == "pacemaker" ] ; then

  # Using pidof is better, to eliminate dependency on the pid file.

  HAPROXY_PID=$(pidof haproxy)
  # HAPROXY_PID=$(cat /var/run/haproxy.pid)

  if [ -z "${HAPROXY_PID}" ] ; then
    echolog "haproxy not running on this node. No need to reload haproxy service... "
  else
    echolog "haproxy running on this node. Needs a soft reload. Soft reloading now ..."

    echo "HAPROXY_PID is $HAPROXY_PID"

    echo "haproxy process - before soft reload..."
    ps aux | grep haproxy | grep -v grep
    echo

    $HAPROXY -f /etc/haproxy/haproxy.cfg  -p /var/run/haproxy.pid -sf $HAPROXY_PID

    # kill -SIGHUP $HAPROXY_PID
    # also: http://stackoverflow.com/questions/20277415/how-to-send-usr2-signal

    echo
    echo "haproxy process - after soft reload ..."
    ps aux | grep haproxy | grep -v grep

  fi 
 
fi

popd 
