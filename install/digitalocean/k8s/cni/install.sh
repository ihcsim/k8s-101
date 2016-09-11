#!/bin/bash

# Installation instructions taken from https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-worker.md#kubelet
sudo mkdir -p /opt/cni
wget https://storage.googleapis.com/kubernetes-release/network-plugins/cni-c864f0e1ea73719b8f4582402b0847064f9883b0.tar.gz
sudo tar -xvf cni-c864f0e1ea73719b8f4582402b0847064f9883b0.tar.gz -C /opt/cni
rm cni-c864f0e1ea73719b8f4582402b0847064f9883b0.tar.gz
