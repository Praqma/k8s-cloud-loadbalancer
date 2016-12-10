#!/bin/bash
function readDBFile() {
  FILE=$1

  ORIG_IFS=$IFS
  echo

  # For now, we remove all IP addresses from ens3 interface. Figure out a better way to do it later.
  for i in  $(ip addr show dev ens3| grep -w inet | grep "/32" | awk '{print $2}' ); do 
    ip addr delete ${i} dev ens3
  done

  # Load the number of IPs from the iplist.txt, based on the number of lines in db.txt

  CONTAINER_COUNT=$(grep -v ^$ db.txt | wc -l)

  if [ ${CONTAINER_COUNT} -eq 0 ] ; then 
    echo "No containers in db.txt ! Exiting ..."
    exit 1
  else
    echo "CONTAINER_COUNT is ${CONTAINER_COUNT}"
  fi

  head -${CONTAINER_COUNT} iplist.txt > iplist.txt.subset

  paste -d ' ' db.txt iplist.txt.subset > db-with-public-ips.txt

  FILE=db-with-public-ips.txt

  echo "Reading DB File ${FILE}"
  echo "-------------------------"
  while read -r LINE ; do
    if [ ! -z "$LINE" ] ; then 
      echo "Data Record: $LINE"
      displayFields "$LINE"


      generateIPTablesRules "$LINE"
      echo "============================================================================"
    fi
  done < "$FILE"

  IFS=$ORIG_IFS

}

function displayFields() {
  RECORD="$1"
  FS=' '
  echo "Received: $RECORD"
  read CNAME CIP CPORTS PROTOCOL PUBLICIP <<< $(echo $RECORD | awk -F "${FS}" '{print $1, $2, $3 , $4 , $5}')
  echo "CNAME: $CNAME  - CIP: $CIP - CPORTS: $CPORTS - PROTOCOL: $PROTOCOL - PUBLICIP: $PUBLICIP"
}


function generateIPTablesRules() {
  RECORD="$1"
  FS=' '
  echo "Received: $RECORD"
  read CNAME CIP CPORTS PROTOCOL PUBLICIP <<< $(echo $RECORD | awk -F "${FS}" '{print $1, $2, $3 , $4 , $5}')

  echo "Generating IPTables rules for:   CNAME: $CNAME  - CIP: $CIP - CPORTS: $CPORTS - PROTOCOL: $PROTOCOL -  PUBLICIP: $PUBLICIP"

  echo Executing iptables -t nat -A DOCKER -d ${PUBLICIP} ! -i docker0 -p ${PROTOCOL} -m ${PROTOCOL} \
           -m comment --comment \"PRAQMA-${CNAME}\" \
           -m multiport --dports ${CPORTS} \
           -j DNAT --to-destination ${CIP}

  iptables -t nat -A DOCKER -d ${PUBLICIP} ! -i docker0 -p ${PROTOCOL} -m ${PROTOCOL} \
           -m comment --comment \"PRAQMA-${CNAME}\" \
           -m multiport --dports ${CPORTS} \
           -j DNAT --to-destination ${CIP}

  # This is the point where we should call some DNS routine to add this PUBLIC IP in DNS zone.
  # What that call should look like is not known yet.

  # also add this PUBLICIP to the ens3 interface. using /32. 
  ip addr add ${PUBLICIP}/32 dev ens3
}




buildDBWithContainersListWithIPandPorts() {
  CURL_COMMAND="curl -s --unix-socket /var/run/docker.sock http:/containers/json"
  local CONTAINER_NAMES=$( ${CURL_COMMAND} | jq '.[].Names[0]' | tr -d '"' )

  #  Empty the db.txt . Note that sending '' to a file is actually sending at lease one null character, which creates a newline.
  # So better use truncate to empty a file. 
  truncate -s 0 db.txt  

  # Run a loop and build the db.txt file
  for CNAME in ${CONTAINER_NAMES}; do
    # echo $CNAME

    local CIP=$(curl -s --unix-socket /var/run/docker.sock http:/containers/json  | jq ".[] | select( .Names[0] == \"${CNAME}\" ) | .NetworkSettings.Networks.bridge.IPAddress" | tr -d '"' ) 
    # echo "Found IP: $CIP"

    local SERVICE_PORTS_TCP=$(curl -s --unix-socket /var/run/docker.sock http:/containers/json | jq ".[] | select( .Names[0] == \"${CNAME}\" ) | .Ports[].PrivatePort" | tr '\n' ',' | sed 's/,$/\n/')
    # echo "Found Ports: $SERVICE_PORTS_TCP"
    # echo
    echo "Found: ${CNAME} ${CIP} ${SERVICE_PORTS_TCP} tcp"

    # write this data in the db.txt file
    echo "${CNAME} ${CIP} ${SERVICE_PORTS_TCP} tcp" >> db.txt
  done
}



