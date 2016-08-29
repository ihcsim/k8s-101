#!/bin/bash

set -e

COREOS_IMAGE=${COREOS_IMAGE:-coreos-stable}
REGION=${REGION:-TOR1}
MEMORY_SIZE=${MEMORY_SIZE:-1GB}
TAG=${TAG:-k8s-cluster}
TLS_ENABLED=${TLS_ENABLED:-false}

cloud_config_file=coreos/cloud-config
if [ "$TLS_ENABLED" = true ]; then
  echo -e "\033[0;32mEnabling TLS mode...\033[0m"
  cloud_config_file=coreos/tls/cloud-config
fi

# create droplet tag if not exist
tag_name=`doctl compute tag get $TAG -o json | jq '.[0]?.name'`
if [ -z $tag_name ] ; then
  echo -e "\033[0;32mCreating new tag \"$TAG\"...\033[0m"
  doctl compute tag create $TAG > /dev/null
fi

echo -e "\033[0;32mCreating droplets coreos-01, coreos-02, coreos-03...\033[0m"
doctl compute droplet create coreos-01 coreos-02 coreos-03 \
  --image "$COREOS_IMAGE" \
  --enable-private-networking \
  --region $REGION \
  --size $MEMORY_SIZE \
  --user-data-file $cloud_config_file \
  --tag-name $TAG \
  --ssh-keys ${SSH_KEY_ID:?Missing SSH key ID or fingerprint. Run \'$ doctl compute ssh-key list\' to view your list of SSH keys on DO.}
echo -e "\033[0;32mCompleted\033[0m"
