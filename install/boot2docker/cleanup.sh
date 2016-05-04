#!/bin/bash

docker stop kubelet 
docker rm kubelet
docker stop `docker ps -q -f name=k8s`
docker rm `docker ps -a -q -f name=k8s`

sleep 2
docker-machine ssh `docker-machine active` <<EOF
sudo umount \$(cat /proc/mounts | grep /var/lib/kubelet | awk '{print $2}')
sudo rm -rf /var/lib/kubelet
EOF
