# It is important to load apireader functions, which are used in this file.
source ../apiReader/apiReader.f

function createLoadBalancer(){
  local LBType=$1
  local NameSpace=$2

  # Setting LBType to haproxy - if not specified explicitly. 
  # Apache works in a different way when used as proxy (as it is only a web proxy), so it is not recommended anyway.
  if [ -z "$LBType" ];then
     echo "Setting HAProxy as Loadbalancer engine (default)"
     LBType="haproxy"
  fi


  if [ -z "$NameSpace" ];then
     echo "No NameSpace specified. Setting NameSpace to 'default'."
     NameSpace="default"
  fi

  if [ "$LBType" = "haproxy"  ]; then
    echo "Executing: createLBHaproxy ${NameSpace}"
    createLBHaproxy ${NameSpace}
  else
    echo "Unknown LBType passed to this function (createoadBalancer). Please investigate."
  fi



  ## Copy the generated config file to /etc/haproxy
  cp haproxy.cfg /etc/haproxy/haproxy.cfg


  # Remove previously generated .cfg and .lb files
  # The default config file is haproxy.cfg.global-defaults , which will not be deleted by the commands below.
  rm -f *.cfg 
  rm -f *.lb 

} 

function createLBHaproxy(){
  # todo: Need to have a way to pass the name of namespace to this function,  if not "default"

  local NameSpace=$1
  local Services=$(getServices ${NameSpace} | tr " " "\n")
  local Nodes=$(getNodeNames)
  local nodeIP=""
  local line=""

  cp haproxy.cfg.global-defaults haproxy.cfg

  printf '%s\n' "$Services" | (while IFS= read -r line
  do
    createServiceLBHaproxy "$line" "$NameSpace" "$Nodes" & 
  done
  wait
  )

#  echo "<SERVICES>" >> haproxy.cfg

  cat *.lb >> haproxy.cfg
  rm -f *.lb
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

  local ServiceFileName="${NameSpace}.${Service}.${ServicePort}.lb"

  # Generate the listen section in haproxy for this particular service 
  if [ ! "$NodePort" == "null" ] && [ ! -z "$Endpoints" ]; then
    echo "Generating service related section in ${ServiceFileName} file ..."

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

