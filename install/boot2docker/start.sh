#!/bin/bash

set -x
K8S_VERSION=1.2.2
HOSTNAME=127.0.0.1.nip.io
API_SERVERS=http://${HOSTNAME}:8080
DNS_SERVER=10.0.0.10
CLUSTER_DOMAIN=cluster.local

docker run \
  --volume=/:/rootfs:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:rw \
  --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
  --volume=/var/run:/var/run:rw \
  --net=host \
  --pid=host \
  --privileged=true \
  --name=kubelet \
  -d \
  gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
  /hyperkube kubelet \
  --containerized \
  --hostname-override=${HOSTNAME} \
  --address="0.0.0.0" \
  --api-servers=${API_SERVERS} \
  --config=/etc/kubernetes/manifests \
  --cluster-dns=${DNS_SERVER} \
  --cluster-domain=${CLUSTER_DOMAIN} \
  --allow-privileged=true \
  --v=2

docker-machine ssh `docker-machine active` -N -L 8080:127.0.0.1.nip.io:8080 &
