#!/bin/bash
# It is important to load apireader functions, which are used in this file.
API_READER=/root/k8s-cloud-loadbalancer/apiReader/apiReader.f
LB_NODEPORT_CONF=/root/k8s-cloud-loadbalancer/lb-nodeport/lb-nodeport.conf


function echolog() {
  MESSAGE=$1
  echo -e $MESSAGE
  logger $MESSAGE
}

# CHeck if API reader functions file is readable. Without it we are doomed :(
if [ -f ${API_READER} ] ; then
  source $API_READER
else
  echolog "API reader was not found at location: ${API_READER}. Exiting ... "
  exit 9
fi 


if [ -f ${LB_NODEPORT_CONF} ] ; then
  source $LB_NODEPORT_CONF
else
  echolog "CONF file  was not found at location: ${LB_NODEPORT_CONF}. Exiting ... "
  exit 9
fi



####################### START - tools/function #################################

function createLoadBalancer(){
  local LBType=$1
  local NameSpace=$2

  # Setting LBType to haproxy - if not specified explicitly. 
  # Apache works in a different way when used as proxy (as it is only a web proxy), so it is not recommended anyway.
  if [ -z "$LBType" ];then
     echolog "Setting HAProxy as Loadbalancer engine (default)"
     LBType="haproxy"
  fi


  if [ -z "$NameSpace" ];then
     echolog "No NameSpace specified. Setting NameSpace to 'default'."
     NameSpace="default"
  fi

  if [ "$LBType" = "haproxy"  ]; then
    echolog "Executing: createLBHaproxy ${NameSpace}"
    createLBHaproxy ${NameSpace}
  else
    echolog "Unknown LBType passed to this function (createLoadBalancer). Please investigate."
  fi



  echolog "Copying the generated config file to /etc/haproxy/"
  cp ${LB_NODEPORT_PATH}/haproxy.cfg /etc/haproxy/haproxy.cfg


  echolog "Remove previously generated .cfg and .lb files"
  # The default config file is haproxy.cfg.global-defaults , which will not be deleted by the commands below.
  rm -f ${LB_NODEPORT_PATH}/*.cfg 
  rm -f ${LB_NODEPORT_PATH}/*.lb 

} 

function createLBHaproxy(){
  # todo: Need to have a way to pass the name of namespace to this function,  if not "default"

  local NameSpace=$1
  local Services=$(getServices ${NameSpace} | tr " " "\n")
  echo "Sevice found: $Services"
  local Nodes=$(getNodeNames)
  local nodeIP=""
  local line=""

  cp ${LB_NODEPORT_PATH}/haproxy.cfg.global-defaults ${LB_NODEPORT_PATH}/haproxy.cfg

  printf '%s\n' "$Services" | (while IFS= read -r line
  do
    createServiceLBHaproxy "$line" "$NameSpace" "$Nodes" & 
  done
  wait
  )

  #  echo "<SERVICES>" >> ${LB_NODEPORT_PATH}/haproxy.cfg

  cat ${LB_NODEPORT_PATH}/*.lb >> ${LB_NODEPORT_PATH}/haproxy.cfg
  rm -f ${LB_NODEPORT_PATH}/*.lb
}

function createServiceLBHaproxy(){
  local Service=$1
  local NameSpace=$2
  local Nodes=$(echo $3 | tr " " "\n")
  local line=""
  local i=1

  local NodePort=$(getServiceNodePorts $Service $NameSpace)

  # The following will give the IPs of the pods. (Needed to check if a service has endpoints or not).
  local Endpoints=$(getServiceEndpoints $Service $NameSpace)


  local ServicePort=$(getServicePort $Service $NameSpace)

  local ServiceFileName="${LB_NODEPORT_PATH}/${NameSpace}.${Service}.${ServicePort}.lb"

  echo "NodePort value: $NodePort"
  echo "EndPoints value: $Endpoints"

  # Generate the listen section in haproxy for this particular service 
  if [ ! "$NodePort" == "null" ] && [ ! -z "$Endpoints" ]; then
    echolog "Generating service related section in ${ServiceFileName} file ..."

    ## Format:
    ## listen apache
    ##   bind 192.168.121.12:ServicePort
    ##   server pod1 10.246.82.10:NodePort check
    ##   server pod2 10.246.82.9:31380 check


    echo "listen ${NameSpace}.${Service}.${ServicePort}"   >> ${ServiceFileName}
    echo -e "\t bind *:${ServicePort}"    >> ${ServiceFileName} 
    echo -e "\t option forwardfor"   >> ${ServiceFileName}

    ## I am not sure about the following options. Do we need them in every service?
    ## echo -e "\t http-request set-header X-Forwarded-Port %[dst_port]"    >> ${ServiceFileName}
    ## echo -e "\t http-request add-header X-Forwarded-Proto https if { ssl_fc }"    >> ${ServiceFileName}
    ## echo -e "\t option httpchk HEAD / HTTP/1.1\r\nHost:localhost"    >> ${ServiceFileName}

    i=1
    # printf '%s\n' "$Nodes" | while IFS= read -r line
    for IP in $(getNodeIPs);  do
      # local nodeIP=$(getNodeIPs $line)
      echo -e "\t server Node_${i} ${IP}:${NodePort} check"    >> ${ServiceFileName}
      i=$((i+1))
    done
  fi

}


