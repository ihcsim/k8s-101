#!/bin/bash

doctl compute droplet delete coreos-01 coreos-02 coreos-03
doctl compute tag delete k8s-cluster
