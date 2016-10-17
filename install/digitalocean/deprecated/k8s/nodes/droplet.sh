#!/bin/bash

set -e

k8s_dir=`dirname $0`
cloud_config_k8s_tmpl=$k8s_dir/cloud-config.tmpl
cloud_config_k8s_file=$k8s_dir/cloud-config

if [ -z "$ETCD_01_PRIVATE_IP" ] || [ -z "$ETCD_02_PRIVATE_IP" ] || [ -z "$ETCD_03_PRIVATE_IP" ] || [ -z "$API_SERVER_PRIVATE_IPV4" ]; then
  echo -e "\033[0;31mCan't create k8s-nodes droplets. Please provide the private IP addresses of droplet etcd-01, etcd-02, etcd-03 and k8s-master using the \$ETCD_01_PRIVATE_IP, \$ETCD_02_PRIVATE_IP, \$ETCD_03_PRIVATE_IP and \$API_SERVER_PRIVATE_IPV4 variables, respectively.\033[0m"
  exit 1
fi

echo -e "\033[0;32mSetting up configuration to connect to etcd-01 ($ETCD_01_PRIVATE_IP), etcd-02 ($ETCD_02_PRIVATE_IP), etcd-03 ($ETCD_03_PRIVATE_IP)...\033[0m"
cp $cloud_config_k8s_tmpl $cloud_config_k8s_file
sed -i '' s%\<etcd-01-private-ip\>%$ETCD_01_PRIVATE_IP%g $cloud_config_k8s_file
sed -i '' s%\<etcd-02-private-ip\>%$ETCD_02_PRIVATE_IP%g $cloud_config_k8s_file
sed -i '' s%\<etcd-03-private-ip\>%$ETCD_03_PRIVATE_IP%g $cloud_config_k8s_file
sed -i '' s%\<version\>%${K8S_VERSION:-v1.3.6}%g $cloud_config_k8s_file
sed -i '' s%\<private_ipv4\>%${APISERVER_PRIVATE_IPV4:-127.0.0.1}%g $cloud_config_k8s_file
sed -i '' s%\<insecure_port\>%${APISERVER_INSECURE_PORT:-7000}%g $cloud_config_k8s_file

echo -e "\033[0;32mCreating droplets k8s-node-01 k8s-node-02...\033[0m"
doctl compute droplet create k8s-node-01 k8s-node-02 \
  --image ${COREOS_IMAGE:-"coreos-stable"} \
  --enable-private-networking \
  --region ${REGION:-SFO2} \
  --size ${MEMORY_SIZE:-1GB} \
  --user-data-file $cloud_config_k8s_file \
  --ssh-keys ${SSH_KEY_ID:?Missing SSH key ID. Use the SSH_KEY_ID variable to specify the SSH key ID. Run \'$ doctl compute ssh-key list\' to view your list of SSH keys on DO.}
doctl compute droplet tag k8s-node-01 k8s-node-02 --tag-name ${TAG:-k8s-cluster}
echo -e "\033[0;32mCompleted\033[0m"
