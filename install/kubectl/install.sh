#!/bin/bash

VERSION=${VERSION:-v1.3.0}
OS=${OS:-darwin}
ARCH=${ARCH:-amd64}
curl -Lo kubectl http://storage.googleapis.com/kubernetes-release/release/$VERSION/bin/$OS/$ARCH/kubectl && \
  chmod +x kubectl && \
  sudo mv kubectl /usr/local/bin/
