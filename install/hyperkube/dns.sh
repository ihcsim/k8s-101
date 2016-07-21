#!/bin/bash

CLUSTER_DOMAIN=cluster.local

export DNS_REPLICAS=1
export DNS_DOMAIN=${CLUSTER_DOMAIN}
export DNS_SERVER_IP=10.0.0.10

sed -e "s/{{ pillar\['dns_replicas'\] }}/${DNS_REPLICAS}/g;s/{{ pillar\['dns_domain'\] }}/${DNS_DOMAIN}/g;s/{{ pillar\['dns_server'\] }}/${DNS_SERVER_IP}/g" skydns.yaml.in > ./skydns.yaml
