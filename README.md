# k8s-101

k8s-101 contains sample scripts to install [Kubernetes](http://kubernetes.io/) and  run some sample applications. The `install` folder contains different flavors of start-up scripts.

# Table of Content

* [Installation](#installation)
  * [kubectl](#kubectl)
  * [minikube](#minikube)
  * [hyperkube](#hyperkube)
* [Applications](#applications)
  * [GuestBook](#guestbook)
  * [Ticker](#ticker)
  * [nginx](#nginx)
* [LICENSE](#license)

## Installation

Install the vendored dependencies using [glide](https://github.com/Masterminds/glide).

```sh
$ curl https://glide.sh/get | sh # install glide
$ glide install
```

## kubectl

Download and install kubectl using the `install/kubectl/install.sh` script. Refer the k8s [docs](http://kubernetes.io/docs/getting-started-guides/minikube/#install-kubectl) for further information.

The `install.sh` script accepts the following environmental variables:

Variables | Description | Default
--------- | ----------- | -------
VERSION   | Version of kubectl to download | 0.8.0
OS        | Build of the binary | darwin
ARCH      | Build of the binary | amd64

## minikube
Run the `install/minikube/install.sh` script to install [minikube](https://github.com/kubernetes/minikube/blob/master/README.md).

The `install.sh` script accepts the following environmental variables:

iVariables | Description | Default
--------- | ----------- | -------
VERSION   | minikube version to download | v0.7.1
PLATFORM  | Build of the binary | darwin
ARCH      | Build of the binary | amd64

For installation prerequisite, refer minikube installation instruction [here](https://github.com/kubernetes/minikube/blob/master/README.md#requirements).

To start the k8s cluster, run
```sh
$ minikube start --vm-driver={virtualbox|vmwarefusion|kvm|xhyve}
```

## hyperkube
**Per the k8s [Getting Started Guide](http://kubernetes.io/docs/getting-started-guides/docker/), hyperkube is no longer the preferred approach to run k8s locally. Try [minikube](#minikube) instead.**

The `install/hyperkube/start.sh` can be used to start up k8s server components using [hyperkube](https://github.com/kubernetes/kubernetes/tree/master/cluster/images/hyperkube). As of k8s [1.3.0](https://github.com/kubernetes/kubernetes/commit/6c53c6a997b2f28eb4326656b9819b098454d6eb), SkyDNS and the k8s Dashboard are installed as part of hyperkube. In this installation, k8s will be set up to listen at 127.0.0.1.nip.io:8080. Modify the `HOSTNAME` variable to change the server's listening address.

```sh
$ cd install/hyperkube
$ ./start.sh             # run the k8s docker containers
$ ./kubectl cluster-info # view cluster info. If this didn't work, configure kubectl as shown in the next section

# for pre-1.3.0 only
$ ./kube-system.yml      # set up the kube-system namespace
$ ./skydns.yml           # set up skydns in the kube-system namespace
$ ./dashboard.yml        # set up the k8s dashboard in the kube-system namespace
$ curl 127.0.0.1.nip.io
```

You can also navigate to the k8s dashboard from your web browser at http://127.0.0.1.nip.io:8080/ui/.

### Configure kubectl
This is an optional set-up that adds the hyperkube k8s cluster to your `~/.kube/config` file.
```sh
$ kubectl config set-cluster hyperkube --server=http://127.0.0.1.nip.io:8080 --api-version=1
$ kubectl config set-context local-k8s --cluster=hyperkube
$ kubectl config use-context local-k8s
$ kubectl cluster-info
Kubernetes master is running at http://127.0.0.1.nip.io:8080
```

### Clean Up
Clean up the Docker containers using `docker rm -f $(docker ps -aq)`. Note this removes all containers running under Docker, so use with caution.

When using Docker Machine, clean up the filesystem by doing:
```
$ docker-machine ssh `docker-machine active`
$ grep /var/lib/kubelet /proc/mounts | awk '{print $2}' | sudo xargs -n1 umount
$ sudo rm -rf /var/lib/kubelet
```


## Applications

### GuestBook
The [guestBook](/apps/guestbook) application is based on the example from the k8s [documentation](https://github.com/kubernetes/kubernetes/tree/release-1.2/examples/guestbook/).

To deploy the application:
```sh
$ kubectl create -f apps/guestbook/redis.yml    # create redis master service and deployment
$ kubectl create -f apps/guestbook/frontend.yml # create the guestbook app
$ kubectl get deployment # verify the deployment
NAME           DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
frontend       3         3         3            3           9m
redis-master   1         1         1            1           18m
redis-slave    2         2         2            2           18m
$ kubectl get svc # verify the service
NAME          CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
frontend      10.0.0.103   <nodes>       80/TCP     10m
redis-slave   10.0.0.47    <none>        6379/TCP   19m
```

The `frontend` service is deployed with its `nodePort` set to 32100. To access the application from a web browser, navigate to http://<MINIKUBE_VM_IP>:32100 where `MINIKUBE_VM_IP` can be retrieved using `$ kubectl describe pod minikubevm` under the `Addresses` field..

To remove the application's deployment and service resources, use the `cleanup.sh` script:
```sh
$ ./apps/guestbook/cleanup.sh
```

### Ticker
The [ticker](/apps/ticker) is a simple shell script to output a continuous string of current datetime.

To deploy the application:
```sh
$ kubectl create -f app/ticker/deployment.yml # create the ticker deployment with replications
```

### nginx
The [nginx](http://nginx.org/en/) server front by a secure k8s TLS service. The code to generate the self-signed RSA key and certificate is based on this k8s [example](https://github.com/kubernetes/kubernetes/tree/672d5a777d5df35cc1e74c8075e3c17a20c4c20b/examples/https-nginx).

Use the k8s `secret` API to generate the self-signed RSA key and certificate that the server can use for TLS:
```sh
$ make -C api/secret keys secret KEY_OUT=`PWD`/apps/nginx/nginx.key CERT_OUT=`PWD`/apps/nginx/nginx.crt SECRET_OUT=`PWD`/apps/nginx/secret.json SECRET_NAME=nginxsecret SVC_NAME=nginx
$ kubectl create -f apps/nginx/secret.json
```

To deploy the Nginx application and its service:
```sh
$ kubectl create -f app/nginx/deployment.yml
```

Use the `curlssl` application to verify SSL access:
```sh
$ kubectl create -f app/nginx/curl.yml
$ kubectl exec <curl-nginx-pod> -- curl https://nginx --cacert /etc/nginx/ssl/nginx.crt
```

To view details of the Nginx service and pods endpoints:
```sh
$ kubectl get svc nginx -o wide
$ kubectl describe svc nginx
$ kubectl get ep nginx
```

Use the [tutum/dnsutils](https://hub.docker.com/r/tutum/dnsutils/) image to verify DNS resolution:
```sh
$ kubectl run dnsutil --image tutum/dnsutils -i --tty
root@dnsutil-1330864204-ygcp2:/# nslookup nginx
root@dnsutil-1330864204-ygcp2:/# dig nginx
```

## LICENSE

This project is under Apache v2 License. See the [LICENSE](LICENSE) file for the full license text.
