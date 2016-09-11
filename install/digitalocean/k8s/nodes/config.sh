#!/bin/bash

if [ -z "${K8S_APISERVER_PRIVATE_IP}" ] || [ -z "${K8S_APISERVER_INSECURE_PORT}" ]  || [ -z "${K8S_USER_TOKEN}" ]; then
  echo -e "\033[0;31mCan't create the kubelet config file. Please provide the private IP addresses and listening port of the k8s-master droplet and a user token using the \$K8S_APISERVER_PRIVATE_IP, \$K8S_APISERVER_INSECURE_PORT and the \$USER_TOKEN variables, respectively.\033[0m"
  exit 1
fi

cp kubeconfig.tmpl kubeconfig
sed -i '' s%\<k8s-apiserver-private-ip\>%${K8S_APISERVER_PRIVATE_IP}%g kubeconfig
sed -i '' s%\<k8s-apiserver-insecure-port\>%${K8S_APISERVER_INSECURE_PORT:-7000}%g kubeconfig
sed -i '' s%\<k8s-user-token\>%${K8S_USER_TOKEN}%g kubeconfig
