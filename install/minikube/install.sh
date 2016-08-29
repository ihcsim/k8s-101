#!/bin/bash

set -e

VERSION=${VERSION:-v0.8.0}
OS=${OS:-darwin}
ARCH=${ARCH:-amd64}

curl -Lo minikube https://storage.googleapis.com/minikube/releases/$VERSION/minikube-$OS-$ARCH \
  && chmod +x minikube \
  && sudo mv minikube /usr/local/bin/

EXIT_STATUS=$?
if [ $? != 0 ]; then
  echo "Failed to install minikube"
  exit $EXIT_STATUS
else
  echo "Successfully install `minikube version`"
fi
