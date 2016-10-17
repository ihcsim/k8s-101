The Makefile in the `install/digitalocean/` folder contains all the targets needed to configure and boot the CoreOS droplets. The `SSH_KEY_ID` variable must be assigned to boot the CoreOS droplets correctly. This variable can be either the ID or fingerprint your existing SSH key on DigitalOcean. These information can be obtained either from the DigitalOcean Control Plane UI or using the doctl CLI with:
```sh
$ doctl compute ssh-key list
```

#### Booting Etcd Droplets
Use the `make etcd` target to create three etcd droplets (with private networking enabled) on DigitalOcean. The default OS image used is the `coreos-stable` image. This can be overriden using the `COREOS_IMAGE` variable.

A new discovery URL is automatically obtained from https://discovery.etcd.io/new?size=$CLUSTER_SIZE to help connect etcd instances together by storing a list of peer addresses, metadata and the initial size of the cluster under this unique address.
```sh
$ SSH_KEY_ID=<ssh-key-id> make droplet-etcd
coreos/droplet.sh
Using discovery token xxxxxxxxxxxx...
Creating new tag "k8s-cluster"...
Name           Droplet Count
k8s-cluster        0
Creating droplets etcd-01, etcd-02, etcd-03...
ID             Name       Public IPv4        Public IPv6        Memory     VCPUs      Disk       Region                Image                  Status     Tags
25094609       etcd-03                                           1024       1          30         sfo2       CoreOS 1122.2.0 (stable)           new
25094612       etcd-01                                           1024       1          30         sfo2       CoreOS 1122.2.0 (stable)           new
25094611       etcd-02                                           1024       1          30         sfo2       CoreOS 1122.2.0 (stable)           new
Completed
```
Now we will verify the etcd droplets.
```sh
# ssh into the droplet
$ doctl compute ssh core@etcd-01 --ssh-key-path <private_key_path>
CoreOS stable (1068.10.0)
Last login: Mon Aug 29 23:20:19 2016 from xx.xxx.xxx.xx
core@coreos-01 ~ $ fleetctl list-machines
MACHINE        IP               METADATA
0fae7524...    xx.xxx.xx.xx       -
2ac0d576...    xx.xxx.xx.xx       -
f724fd1b...    xx.xxx.xx.xx       -

# verify etcd2 is running
core@coreos-01 ~ $ systemctl status etcd2
● etcd2.service - etcd2
   Loaded: loaded (/usr/lib64/systemd/system/etcd2.service; disabled; vendor preset: disabled)
  Drop-In: /run/systemd/system/etcd2.service.d
           └─20-cloudinit.conf
   Active: active (running) since Tue 2016-09-06 01:06:27 UTC; 6min ago
 Main PID: 1161 (etcd2)
    Tasks: 7
   Memory: 33.8M
      CPU: 2.437s
   CGroup: /system.slice/etcd2.service
           └─1161 /usr/bin/etcd2

Sep 06 01:06:27 coreos-01 etcd2[1161]: the connection with 295aef39c0c5bca5 became active
Sep 06 01:06:27 coreos-01 etcd2[1161]: added member 295aef39c0c5bca5 [http://xx.xxx.xx.xx:2380] to cluster 4ddb9591cfdf3767
Sep 06 01:06:27 coreos-01 etcd2[1161]: added local member 61df7dc6fd3da92f [http://xx.xxx.xx.xx:2380] to cluster 4ddb9591cfdf3767
Sep 06 01:06:27 coreos-01 etcd2[1161]: added member a0900540d2dd65f9 [http://xx.xxx.xx.xx:2380] to cluster 4ddb9591cfdf3767
Sep 06 01:06:28 coreos-01 etcd2[1161]: 61df7dc6fd3da92f [term: 1] received a MsgVote message with higher term from 295aef39c0c5bca5 [term: 2]
Sep 06 01:06:28 coreos-01 etcd2[1161]: 61df7dc6fd3da92f became follower at term 2
Sep 06 01:06:28 coreos-01 etcd2[1161]: 61df7dc6fd3da92f [logterm: 1, index: 3, vote: 0] voted for 295aef39c0c5bca5 [logterm: 1, index: 3] at term 2
Sep 06 01:06:28 coreos-01 etcd2[1161]: raft.node: 61df7dc6fd3da92f elected leader 295aef39c0c5bca5 at term 2
Sep 06 01:06:28 coreos-01 etcd2[1161]: published {Name:89417d637a31497b94058edfdcff8f6d ClientURLs:[http://xx.xxx.xx.xx:2379 http://xx.xxx.xx.xx:4001]} to cluster 4ddb9591cfdf3767
Sep 06 01:06:28 coreos-01 etcd2[1161]: set the initial cluster version to 2.3

# verifying fleet is running
$ systemctl status fleet
● fleet.service - fleet daemon
   Loaded: loaded (/usr/lib64/systemd/system/fleet.service; disabled; vendor preset: disabled)
  Drop-In: /run/systemd/system/fleet.service.d
            └─20-cloudinit.conf
   Active: active (running) since Thu 2016-09-08 04:55:17 UTC; 2min 11s ago
 Main PID: 1143 (fleetd)
    Tasks: 7
   Memory: 17.7M
      CPU: 1.481s
   CGroup: /system.slice/fleet.service
            └─1143 /usr/bin/fleetd

Sep 08 04:55:17 etcd-01 systemd[1]: Started fleet daemon.
Sep 08 04:55:17 etcd-01 fleetd[1143]: INFO fleetd.go:64: Starting fleetd version 0.11.7
Sep 08 04:55:17 etcd-01 fleetd[1143]: INFO fleetd.go:168: No provided or default config file found - proceeding without
Sep 08 04:55:17 etcd-01 fleetd[1143]: INFO server.go:157: Establishing etcd connectivity
Sep 08 04:55:19 etcd-01 fleetd[1143]: INFO server.go:168: Starting server components
Sep 08 04:55:19 etcd-01 fleetd[1143]: ERROR engine.go:156: Failed updating cluster engine version from 0 to 1: 101: Compare failed ([0 != 1]) [11]
Sep 08 04:55:21 etcd-01 fleetd[1143]: INFO engine.go:79: Engine leader is 2ae37dcd6b564da988b1434dbf3833e3

# verify flanneld is running
core@etcd-01 ~ $ systemctl status flanneld
● flanneld.service - Network fabric for containers
  Loaded: loaded (/usr/lib64/systemd/system/flanneld.service; disabled; vendor preset: disabled)
 Drop-In: /etc/systemd/system/flanneld.service.d
          └─50-network-config.conf
  Active: active (running) since Thu 2016-09-08 04:55:30 UTC; 4min 14s ago
    Docs: https://github.com/coreos/flannel
 Process: 1310 ExecStartPost=/usr/bin/rkt run --net=host --stage1-path=/usr/lib/rkt/stage1-images/stage1-fly.aci --insecure-options=image --volume runvol,kind=host,source=/run,readOnly=false --mount volu
 Process: 1229 ExecStartPre=/usr/bin/etcdctl --endpoints http://${COREOS_PRIVATE_IPV4}:2379 set /coreos.com/network/config { "Network": "10.1.0.0/16" } (code=exited, status=0/SUCCESS)
 Process: 1224 ExecStartPre=/usr/bin/mkdir -p ${ETCD_SSL_DIR} (code=exited, status=0/SUCCESS)
 Process: 1216 ExecStartPre=/usr/bin/mkdir -p /run/flannel (code=exited, status=0/SUCCESS)
 Process: 1212 ExecStartPre=/sbin/modprobe ip_tables (code=exited, status=0/SUCCESS)
Main PID: 1237 (flanneld)
   Tasks: 7
  Memory: 90.7M
     CPU: 3.207s
  CGroup: /system.slice/flanneld.service
          └─1237 /opt/bin/flanneld --ip-masq=true

Sep 08 04:55:30 etcd-01 rkt[1237]: I0908 04:55:30.122080 01237 ipmasq.go:50] Adding iptables rule: FLANNEL -d 10.1.0.0/16 -j ACCEPT
Sep 08 04:55:30 etcd-01 rkt[1237]: I0908 04:55:30.136204 01237 ipmasq.go:50] Adding iptables rule: FLANNEL ! -d 224.0.0.0/4 -j MASQUERADE
Sep 08 04:55:30 etcd-01 rkt[1237]: I0908 04:55:30.155007 01237 ipmasq.go:50] Adding iptables rule: POSTROUTING -s 10.1.0.0/16 -j FLANNEL
Sep 08 04:55:30 etcd-01 rkt[1237]: I0908 04:55:30.163863 01237 ipmasq.go:50] Adding iptables rule: POSTROUTING ! -s 10.1.0.0/16 -d 10.1.0.0/16 -j MASQUERADE
Sep 08 04:55:30 etcd-01 rkt[1237]: I0908 04:55:30.184654 01237 udp.go:222] Watching for new subnet leases
Sep 08 04:55:30 etcd-01 rkt[1310]: image: using image from file /usr/lib/rkt/stage1-images/stage1-fly.aci
Sep 08 04:55:30 etcd-01 rkt[1310]: image: using image from local store for image name quay.io/coreos/flannel:0.5.5
Sep 08 04:55:30 etcd-01 systemd[1]: Started Network fabric for containers.
Sep 08 04:55:31 etcd-01 rkt[1237]: I0908 04:55:31.795220 01237 udp.go:247] Subnet added: 10.1.101.0/24
Sep 08 04:55:38 etcd-01 rkt[1237]: I0908 04:55:38.187175 01237 udp.go:247] Subnet added: 10.1.39.0/24
```

The following is a list of all the variables supported by the `make etcd` target:

Variables      | Description | Default
-------------- | ----------- | -------
`COREOS_IMAGE` | CoreOS image to use for the droplets | coreos-stable
`REGION`       | Region the droplets will reside in | TOR1
`MEMORY_SIZE`  | Memory size of the droplets | 1GB
`TAG`          | Arbitrary tags use to group the droplets | k8s-cluster
`TLS_ENABLED`  | Set to `true` to enable TLS | false
`CLUSTER_SIZE` | The total number of etcd droplets in the cluster. This will be used as a parameter to the discovery URL generator | 3

Repeat the above steps with the etcd-02 and etcd-03 droplets. You should see the subnets of the other droplets are being added by flannel.

#### Booting the K8s Master And Node Droplets
Use the `make k8s-master` and `make k8s-nodes` targets to create one k8s master and two k8s node droplets, respectively, (with private networking enabled) on DigitalOcean. The default OS image used is the `coreos-stable` image. This can be overridden using the `COREOS_IMAGE` variable.
```sh
$ SSH_KEY_ID=xxxxxx ETCD_01_PRIVATE_IP=xx.xxx.xxx.xxx ETCD_02_PRIVATE_IP=xx.xxx.xxx.xxx ETCD_03_PRIVATE_IP=xx.xxx.xxx.xxx make k8s-master
```

Once the droplets are ready, ensure that Docker is running with flannel, where the Docker `bip` and `mtu` options should match the `FLANNEL_SUBNET` and `FLANNEL_MTU`, respectively.
```sh
$ doctl compute ssh core@k8s-master
$ systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib64/systemd/system/docker.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/docker.service.d
           └─40-flannel.conf
   Active: active (running) since Sun 2016-09-11 05:54:22 UTC; 16h ago
     Docs: http://docs.docker.com
 Main PID: 1315 (docker)
    Tasks: 7
   Memory: 35.3M
      CPU: 15.504s
   CGroup: /system.slice/docker.service
           └─1315 docker daemon --host=fd:// --exec-opt native.cgroupdriver=systemd --bip=xx.xx.xx.xx/24 --mtu=xxxx --ip-masq=false --selinux-enabled

Sep 11 05:54:22 k8s-master systemd[1]: Started Docker Application Container Engine.
Sep 11 05:54:23 k8s-master dockerd[1315]: time="2016-09-11T05:54:23.072764719Z" level=info msg="Graph migration to content-addressability took 0.00 seconds"
Sep 11 05:54:23 k8s-master dockerd[1315]: time="2016-09-11T05:54:23.106314196Z" level=info msg="Firewalld running: false"
Sep 11 05:54:23 k8s-master dockerd[1315]: time="2016-09-11T05:54:23.351844420Z" level=info msg="Loading containers: start."
Sep 11 05:54:23 k8s-master dockerd[1315]: time="2016-09-11T05:54:23.352244388Z" level=info msg="Loading containers: done."
Sep 11 05:54:23 k8s-master dockerd[1315]: time="2016-09-11T05:54:23.352547874Z" level=info msg="Daemon has completed initialization"
Sep 11 05:54:23 k8s-master dockerd[1315]: time="2016-09-11T05:54:23.352867806Z" level=info msg="Docker daemon" commit=1f8f545 execdriver=native-0.2 graphdriver=overlay version=1.10.3
Sep 11 05:54:23 k8s-master dockerd[1315]: time="2016-09-11T05:54:23.362295339Z" level=info msg="API listen on /var/run/docker.sock"
```

Download the binaries for the k8s-master.
```sh
$ doctl compute ssh core@k8s-master
$ sudo mkdir -p /opt/bin
$ sudo wget -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-apiserver
$ sudo wget -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-controller-manager
$ sudo wget -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-scheduler
$ sudo wget -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl
$ sudo chmod +x /opt/bin/kube*
```

Generate and copy the `k8s.pem` file to the k8s-master droplet. This PEM file is used to create a service account token which is used to authenticate requests to the API Server. For more information, refer this [post](https://github.com/kubernetes/kubernetes/issues/11222#issuecomment-125827374).
```
# on k8s-master
$ sudo mkdir -p /var/lib/kubernetes
$ sudo chown core:core /var/lib/kubernetes

# on your local machine
$ make k8s-ssl
$ scp ssl/k8s.pem core@<k8s-master-public-ip>:/var/lib/kubernetes
```

Copy the systemd unit files from this repository to the k8s-master droplet.
```sh
$ scp k8s/master/unit-files/* core@<k8s-master-public-ip>:/etc/systemd/system/
$ doctl compute ssh core@k8s-master
$ cd /etc/systemd/system
$ sudo systemctl enable k8s-*.service
$ sudo systemctl start k8s-*.service
```

Now we can run some tests to make sure the k8s master droplet is ready.
```sh
# verify the API server
$ curl http://<k8s-master-public-ip>:<apiserver-insecure-port>
$ kubectl get componentstatuses
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health": "true"}
etcd-2               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
```

Now we are ready set up the k8s nodes. Obtain the private IP address of the k8s-master droplet, and use it to set up the k8s-node-01 and k8s-node-02 droplets.
```
$ APISERVER_PRIVATE_IPV4=xx.xxx.xxx.xxx SSH_KEY_ID=xxxxxx ETCD_01_PRIVATE_IP=xx.xxx.xxx.xxx ETCD_02_PRIVATE_IP=xx.xxx.xxx.xxx ETCD_03_PRIVATE_IP=xx.xxx.xxx.xxx make k8s-nodes
```

Copy the `k8s/cni/install.sh` script to both the `k8s-node-01` and `k8s-node-02` droplets. More information on installing CNI can be found [here](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-worker.md#kubelet).
```sh
$ scp k8s/cni/install.sh core@<k8s-node-public-ip>:/opt/
$ doctl compute ssh core@k8s-node-01
$ /opt/install.sh
```

Download the binaries for the k8s nodes.
```sh
# on the k8s node droplet
$ sudo mkdir -p /opt/bin
$ sudo wget -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl
$ sudo wget -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kube-proxy
$ sudo wget -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubelet
$ sudo chmod +x /opt/bin/kube*
```

Use the `k8s/kubelet/config.sh` script to set up the kubelet's `kubeconfig` file. The k8s-master droplet's private IP address and a random user token must be provided using the `APISERVER_PRIVATE_IP` and `USER_TOKEN` variables, respectively.
```sh
# on the k8s node droplet
$ sudo mkdir -p /var/lib/kubelet/
$ sudo chown core:core /var/lib/kubelet/

# on your local
$ APISERVER_PRIVATE_IPV4=xx.xx.xxx.xx USER_TOKEN=sometoken ./config.sh
$ scp kubeconfig core@<k8s-node-01-public-ip>://var/lib/kubelet/
```

The following is a list of variables supported by the `make droplet-k8s` target:

Variables                       | Description | Default Value
------------------------------- | ----------- | -------------
`SSH_KEY_ID`         (Required) | ID of the SSH key to be used to create the droplets | Can be obtained using the `doctl compute ssh-key list` command
`ETCD_01_PRIVATE_IP` (Required) | Private IP address of the `etcd-01` droplet    | Can be obtained using the `doctl compute droplet get -o json` command
`ETCD_02_PRIVATE_IP` (Required) | Private IP address of the `etcd-02` droplet    | Can be obtained using the `doctl compute droplet  get -o json` command
`ETCD_03_PRIVATE_IP` (Required) | Private IP address of the `etcd-03` droplet    | Can be obtained using the `doctl compute droplet get -o json` command
`APISERVER_PRIVATE_IPV4`        | Private IP address of the `k8s-master` droplet | Can be obtained using the `doctl compute droplet get -o json` command
`K8S_VERSION`                   | k8s version                 | 1.3.6
`APISERVER_INSECURE_PORT`       | HTTP port of the API Server | 7000

Once all the droplets are up, you should see their subnets are being added by flannel by running `systemctl status flanneld`.


