# API describtion found here :
#   http://kubernetes.io/docs/api-reference/v1/operations/
#   http://kubernetes.io/kubernetes/third_party/swagger-ui/
<<<<<<< HEAD
url="--cacert /var/lib/kubernetes/ca.pem --cert /var/lib/kubernetes/kubernetes-combined.pem https://10.240.0.20:6443"
=======
# url="localhost:8001"
url="localhost:8080"
>>>>>>> de7f4612ec1a9f7af4d3021bf2ad35f9454a50ad

function getNodeIPs(){
  local nodename=$1

  if [ ! -z "$nodename" ]; then
    echo $(curl -s $url/api/v1/nodes/$nodename | jq -r '.status.addresses[] | select(.type == "InternalIP") | .address')
  else
    echo $(curl -s $url/api/v1/nodes | jq -r '.items[].status.addresses[] | select(.type == "InternalIP") | .address')
  fi
}

function getNodeNames(){
    echo $(curl -s $url/api/v1/nodes | jq -r '.items[].spec.externalID')
}

function getServices(){
  local namespace=$1

  if [ ! -z "$namespace" ]; then
    echo $(curl -s $url/api/v1/namespaces/$namespace/services/ | jq -r '.items[].metadata.name')
  else
    echo $(curl -s $url/api/v1/services/ | jq -r '.items[].metadata.name')
  fi
}

function getServiceNodePorts(){
  local service=$1
  local namespace=$2

  if [ ! -z "$namespace" ]; then
    echo $(curl -s $url/api/v1/namespaces/$namespace/services/$service | jq -r '.spec.ports[].nodePort')
  else
    echo $(curl -s $url/api/v1/services/ | jq -r '.items[] | select(.metadata.name == "'$service'") | .spec.ports[].nodePort')
  fi

}

function getServiceEndpoints(){
  local service=$1
  local namespace=$2

  if [ "$namespace" == "" ];then
    namespace=$(getServiceNamespace $service)
  fi

  # fetch endpoint section from a service json
  local subset=$(curl -s $url/api/v1/namespaces/$namespace/endpoints/$service | jq -r '.subsets[]')

  # If it has endpoints, get each of them and print them
  if [ ! -z "$subset" ]; then
    echo $(curl -s $url/api/v1/namespaces/$namespace/endpoints/$service | jq -r '.subsets[].addresses[].ip')

  fi
}

function getServiceNamespace(){
  local service=$1
  echo $(curl -s $url/api/v1/services/ | jq -r '.items[] | select(.metadata.name == "'$service'") | .metadata.namespace')
}

function getPods(){
  local namespace=$1

  if [ ! -z "$namespace" ]; then
    echo $(curl -s $url/api/v1/namespaces/$namespace/pods | jq -r '.items[].metadata.name')
  else
    echo $(curl -s $url/api/v1/pods | jq -r '.items[].metadata.name')
  fi
}

function getPodNamespace(){
  local podName=$1
  echo $(curl -s $url/api/v1/pods | jq -r '.items[] | select(.metadata.name == "'$podName'") | .metadata.namespace')
}

function getPodIp(){
  local podName=$1
  local namespace=$2

  if [ ! -z "$namespace" ]; then
    echo $(curl -s $url/api/v1/namespaces/$namespace/pods/$podName | jq -r '.status.podIP')
  fi
}

function getDeployments(){
  local namespace=$1

  if [ ! -z "$namespace" ]; then
    echo $(curl -s $url/apis/extensions/v1beta1/namespaces/$namespace/deployments | jq -r '.items[].metadata.name')
  else
    echo $(curl -s $url/apis/extensions/v1beta1/deployments | jq -r '.items[].metadata.name')
  fi

}

function getEventsAll(){
  local namespace=$1

  if [ ! -z "$namespace" ]; then
    curl -s $url/api/v1/watch/namespaces/$namespace/events
  else
    curl -s $url/api/v1/watch/events
  fi

}


function formatEventStream(){
  # This is an example on how apiReader could be used. We fect a json stream, and compute each chunk.
  # http://stackoverflow.com/questions/30272651/redirect-curl-to-while-loop
  while read -r l; do
    resourceVersion=$(echo "$l" | jq -r '.object.metadata.resourceVersion') 
    reason=$(echo "$l" | jq -r '.object.reason')
    message=$(echo "$l" | jq -r '.object.message')
  
    echo "Event ($resourceVersion) ($reason) : $message"
  done < <(getEventsOnlyNew)

}

function getEventsOnlyNew(){
  local namespace=$1

  if [ ! -z "$namespace" ]; then
    local resourceVersion=$(curl -s $url/api/v1/namespaces/$namespace/events | jq -r '.metadata.resourceVersion')
  else
    local resourceVersion=$(curl -s $url/api/v1/events | jq -r '.metadata.resourceVersion')
  fi

  local onlyNew="?resourceVersion=$resourceVersion"

  if [ ! -z "$namespace" ]; then
     curl -s -N  $url/api/v1/watch/namespaces/$namespace/events$onlyNew --stderr -
  else
    curl -s -N $url/api/v1/watch/events$onlyNew --stderr - 
  fi
}

function getPodEventStream(){
  # If a specific pod is given, apiReader will only return events for this pod
  # Otherwise is will return events for all pods.

  # This function is a copy of getPodEventStreamAll sofar. We hope to be able
  # to give a resourceVersion later on, but it might be done manually.
  # TODO : Get newest resourceVersion and only show events with a higher 
  # resourceVersion number.

  local podname=$1

  if [ ! -z "$podname" ]; then
    curl -s $url/api/v1/watch/pods/$podname
  else
    curl -s $url/api/v1/watch/pods
  fi

}


function getPodEventStreamAll(){
  # If a specific pod is given, apiReader will only return events for this pod
  # Otherwise is will return events for all pods.

  local podname=$1

  if [ ! -z "$podname" ]; then
    curl -s $url/api/v1/watch/pods/$podname
  else
    curl -s $url/api/v1/watch/pods
  fi

}

function getServiceEventStream(){
    curl -s $url/api/v1/watch/services
}

function getDeploymentEventStream(){
    curl $url/apis/extensions/v1beta1/watch/deployments
}
