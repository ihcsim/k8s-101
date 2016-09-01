# k8s-101

k8s-101 contains sample scripts to install [Kubernetes](http://kubernetes.io/) and  run some sample applications. The `install` folder contains different flavors of start-up scripts.

# Table of Content

* [Installation](#installation)
  * [kubectl](#kubectl)
  * [minikube](#minikube)
  * [hyperkube](#hyperkube)
  * [DigitalOcean](#digitalocean)
* [Applications](#applications)
  * [GuestBook](#guestbook)
  * [Ticker](#ticker)
  * [nginx](#nginx)
* [LICENSE](#license)

## Installation

Install the vendored dependencies using [glide](https://github.com/Masterminds/glide).

```sh
$ curl https://glide.sh/get | sh
$ glide install
```

### kubectl
The installation script for kubectl can be found in the `install/kubectl` folder. To download and install kubectl:
```sh
$ make install
```
Refer the k8s [docs](http://kubernetes.io/docs/getting-started-guides/minikube/#install-kubectl) for further information.

The Makefile `install` target accepts the following variables:

Variables | Description | Default
--------- | ----------- | -------
VERSION   | Version of kubectl to download | 0.8.0
OS        | Build of the binary | darwin
ARCH      | Build of the binary | amd64

### minikube
The installation script for minikube can be found in the `install/minikube` folder. To download and install [minikube](https://github.com/kubernetes/minikube/blob/master/README.md):
```sh
$ make install
```
For installation prerequisite, refer minikube installation instruction [here](https://github.com/kubernetes/minikube/blob/master/README.md#requirements).

The Makefile `install` target accepts the following variables:

Variables | Description | Default
--------- | ----------- | -------
VERSION   | minikube version to download | v0.7.1
PLATFORM  | Build of the binary | darwin
ARCH      | Build of the binary | amd64

To start the k8s cluster, run
```sh
$ minikube start --vm-driver={virtualbox|vmwarefusion|kvm|xhyve}
```

### hyperkube
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

#### Configure kubectl
This is an optional set-up that adds the hyperkube k8s cluster to your `~/.kube/config` file.
```sh
$ kubectl config set-cluster hyperkube --server=http://127.0.0.1.nip.io:8080 --api-version=1
$ kubectl config set-context local-k8s --cluster=hyperkube
$ kubectl config use-context local-k8s
$ kubectl cluster-info
Kubernetes master is running at http://127.0.0.1.nip.io:8080
```

#### Clean Up
Clean up the Docker containers using `docker rm -f $(docker ps -aq)`. Note this removes all containers running under Docker, so use with caution.

When using Docker Machine, clean up the filesystem by doing:
```
$ docker-machine ssh `docker-machine active`
$ grep /var/lib/kubelet /proc/mounts | awk '{print $2}' | sudo xargs -n1 umount
$ sudo rm -rf /var/lib/kubelet
```

### DigitalOcean
This section describes the steps to deploy k8s on CoreOS DigitalOcean droplets.

#### Prerequisite

* The DigitalOcean [doctl](https://github.com/digitalocean/doctl) CLI version 1.4.0.
* Generate a new DigitalOcean API token following the instruction found [here](https://github.com/digitalocean/doctl#initialization).
* Obtain a new discovery URL obtained from https://discovery.etcd.io/new. The URL points to a free discovery service provided by CoreOS to help connect etcd instances together by storing a list of peer addresses, metadata and the initial size of the cluster under a unique address, known as the discovery URL.
* Generate a public/private keypairs to be used to access the droplets. More information can be found [here](https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets).

#### Configuring And Booting CoreOS
The Makefile in the `install/digitalocean/coreos` folder contains all the targets needed to configure and boot the CoreOS droplets.

**The `coreos.etcd2.discovery` property in the `install/digitalocean/coreos/cloud-config` script must be updated with a new discovery URL obtained from https://discovery.etcd.io/new everytime a new cluster is built.**

The `SSH_KEY_ID` variable must be set to either the ID or fingerprint your existing SSH key on DigitalOcean. These information can be obtained either from the DigitalOcean Control Plane UI or using the doctl CLI with:
```sh
$ doctl compute ssh-key list
```

Create 3 CoreOS droplets (with private networking enabled) on DigitalOcean.
```sh
$ SSH_KEY_ID=<your_ssh_key_id> make droplet
Creating new tag "k8s-cluster"...
Creating droplets coreos-01, coreos-02, coreos-03...
ID         Name        Public IPv4      Public IPv6      Memory   VCPUs    Disk     Region     Image                          Status   Tags
24345691   coreos-01                                      1024      1        30       tor1     CoreOS 1068.10.0 (stable)        new
24345694   coreos-02                                      1024      1        30       tor1     CoreOS 1068.10.0 (stable)        new
24345692   coreos-03                                      1024      1        30       tor1     CoreOS 1068.10.0 (stable)        new
Completed

# verify the coreos cluster
$ doctl compute ssh core@coreos-01 --ssh-key-path <private_key_path>
CoreOS stable (1068.10.0)
Last login: Mon Aug 29 23:20:19 2016 from xx.xxx.xxx.xx
core@coreos-01 ~ $ fleetctl list-machines
MACHINE        IP               METADATA
0fae7524...    xx.xxx.xx.xx       -
2ac0d576...    xx.xxx.xx.xx       -
f724fd1b...    xx.xxx.xx.xx       -
```

Other supported variables include:

Variables | Description | Default
--------- | ----------- | -------
`COREOS_IMAGE` | CoreOS image to use for the droplets | coreos-stable
`REGION`       | Region the droplets will reside in | TOR1
`MEMORY_SIZE`  | Memory size of the droplets | 1GB
`TAG`          | Arbitrary tags use to group the droplets | k8s-cluster
`TLS_ENABLED`  | Set to `true` to enable TLS | false

#### Securing The CoreOS Droplets With TLS
All the scripts and JSON config files needed to set-up TLS are found in the `install/digitalocean/coreos/tls` folder.

Download the Cloudflare [cfssl](https://github.com/cloudflare/cfssl) CLI:
```sh
make cfssl
```

Update the `ca-config.json` file with your CN, O, OU, C etc. Then generate a fake CA:
```sh
$ make cacert
```

Update the `coreos-01.json`, `coreos-02.json` and `coreos-03.json` files with the private IP addresses of the corresponding droplets. The private IP address of each droplet can be obtained either from the Digital Ocean Control Panel UI or with:
```sh
doctl compute droplet get 24331438 -o json | jq '.[0].networks.v4'
```

Then generate self-signed TLS certificate for all three droplets:
```sh
$ DROPLET_CERT_CONFIG_FILE=coreos/tls/coreos-01.json DROPLET_PUBLIC_IP=<coreos-01-public-ip> make droplet-cert
$ DROPLET_CERT_CONFIG_FILE=coreos/tls/coreos-02.json DROPLET_PUBLIC_IP=<coreos-02-public-ip> make droplet-cert
$ DROPLET_CERT_CONFIG_FILE=coreos/tls/coreos-03.json DROPLET_PUBLIC_IP=<coreos-03-public-ip> make droplet-cert

# verify the cluster
$ doctl compute ssh core@coreos-01
CoreOS stable (1068.10.0)
Last login: Thu Sep  1 00:46:40 2016 from xx.xxx.xxx.xx
Failed Units: 1
  iptables-restore.service
$ core@coreos-01 ~ $ fleetctl list-machines
  MACHINE    IP               METADATA
2661d2e1...  xx.xxx.xxx.xxx    -
7f8f1872...  xx.xxx.xxx.xxx    -
970c750a...  xx.xxx.xxx.xx     -

# verify etcd is running
$ systemctl status -l etcd2
● etcd2.service - etcd2
  Loaded: loaded (/usr/lib64/systemd/system/etcd2.service; disabled; vendor preset: disabled)
 Drop-In: /run/systemd/system/etcd2.service.d
          └─20-cloudinit.conf, 30-certificate.conf
  Active: active (running) since Thu 2016-09-01 00:46:25 UTC; 1min 21s ago
Main PID: 2605 (etcd2)
   Tasks: 7
  Memory: 26.4M
     CPU: 1.212s
  CGroup: /system.slice/etcd2.service
          └─2605 /usr/bin/etcd2

# verify etcd TLS config
core@coreos-01 ~ $ cat /run/systemd/system/etcd2.service.d/20-cloudinit.conf
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=https://xx.xxx.xx.xx:2379,https://xx.xxx.xx.xx:4001"
Environment="ETCD_DISCOVERY=https://discovery.etcd.io/<token>"
Environment="ETCD_INITIAL_ADVERTISE_PEER_URLS=https://xx.xxx.xx.xx:2380"
Environment="ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379,https://0.0.0.0:4001"
Environment="ETCD_LISTEN_PEER_URLS=https://xx.xxx.xx.xx:2380"

# verify fleet is running
core@coreos-01 ~ $ systemctl status -l fleet
● fleet.service - fleet daemon
   Loaded: loaded (/usr/lib64/systemd/system/fleet.service; disabled; vendor preset: disabled)
  Drop-In: /run/systemd/system/fleet.service.d
           └─20-cloudinit.conf, 30-certificates.conf
   Active: active (running) since Thu 2016-09-01 00:46:25 UTC; 1min 37s ago
 Main PID: 2623 (fleetd)
    Tasks: 7
   Memory: 11.1M
      CPU: 1.143s
   CGroup: /system.slice/fleet.service
           └─2623 /usr/bin/fleetd

# verify fleet TLS config
core@coreos-01 ~ $ cat /run/systemd/system/fleet.service.d/20-cloudinit.conf
[Service]
Environment="FLEET_ETCD_SERVERS=https://xx.xxx.xx.xx:4001"
Environment="FLEET_PUBLIC_IP=xx.xxx.xx.xx"
```

#### Clean Up
Use the `install/digitalocean/coreos/cleanup.sh` script to destroy the coreos-01, coreos-02 and coreos-03 droplets and the `k8s-cluster` tag.

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

