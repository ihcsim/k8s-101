#!/bin/bash

set -e

etcd_dir=`dirname $0`
cloud_config_etcd_tmpl=$etcd_dir/cloud-config.tmpl
cloud_config_etcd_file=$etcd_dir/cloud-config

DISCOVERY_URL=`curl https://discovery.etcd.io/new?size=${CLUSTER_SIZE:-3}`
echo -e "\033[0;32mUsing discovery URL $DISCOVERY_URL...\033[0m"
cp $cloud_config_etcd_tmpl $cloud_config_etcd_file
sed -i '' s%\<discovery-url\>%$DISCOVERY_URL%g $cloud_config_etcd_file

# create droplet tag if not exist
TAG=${TAG:-k8s-cluster}
tag_name=`doctl compute tag get $TAG -o json | jq '.[0]?.name'`
if [ -z $tag_name ] ; then
  echo -e "\033[0;32mCreating new tag \"$TAG\"...\033[0m"
  doctl compute tag create $TAG
fi

echo -e "\033[0;32mCreating droplets etcd-01, etcd-02, etcd-03...\033[0m"
doctl compute droplet create etcd-01 etcd-02 etcd-03 \
  --image ${COREOS_IMAGE:-"coreos-stable"} \
  --enable-private-networking \
  --region ${REGION:-SFO2} \
  --size ${MEMORY_SIZE:-1GB} \
  --user-data-file $cloud_config_etcd_file \
  --ssh-keys ${SSH_KEY_ID:?Missing SSH key ID. Use the SSH_KEY_ID variable to specify the SSH key ID. Run \'$ doctl compute ssh-key list\' to view your list of SSH keys on DO.}
doctl compute droplet tag etcd-01 etcd-02 etcd-03 --tag-name $TAG
echo -e "\033[0;32mCompleted\033[0m"
