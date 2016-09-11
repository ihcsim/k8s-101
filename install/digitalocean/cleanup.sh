#!/bin/bash

set -e

rm -f `dirname $0`/k8s/master/cloud-config
rm -f `dirname $0`/k8s/nodes/cloud-config
rm -rf `dirname $0`/ssl

TAG=${TAG:-k8s-cluster}
ids=`doctl compute droplet list --tag-name $TAG --format ID --no-header`
for id in $ids; do
  doctl compute droplet delete $id
done
doctl compute tag delete $TAG
