# k8s-101

k8s-101 contains sample scripts that are used to get [Kubernetes](http://kubernetes.io/) up and running. The `install` folder contains different flavors of start-up scripts.

## Installation - boot2docker

`install\boot2docker` contains scripts to run K8s with SkyDNS and K8s Dashboard using Docker on your local laptop. K8s will be set up to listen at 127.0.0.1.nip.io:8080. Modify the `HOSTNAME` variable to change this setting.

```sh
$ cd install/boot2docker
$ ./start.sh             # run the K8s docker containers
$ ./kubectl cluster-info # view cluster info. If this didn't work, configure kubectl as shown in the next section
$ ./kube-system.yml      # set up the kube-system namespace
$ ./skydns.yml           # set up skydns in the kube-system namespace
$ ./dashboard.yml        # set up the K8s dashboard in the kube-system namespace
$ curl 127.0.0.1.nip.io
```

You can also navigate to the K8s dashboard from your web browser at http://127.0.0.1.nip.io:8080/ui/.

### Configure kubectl 

This is an optional set-up that adds the boot2docker K8s cluster to your `~/.kube/config` file.
```sh
$ kubectl config set-cluster boot2docker --server=http://127.0.0.1.nip.io:8080 --api-version=1
$ kubectl config set-context local-k8s --cluster=boot2docker
$ kubectl config use-context local-k8s
$ kubectl cluster-info
Kubernetes master is running at http://127.0.0.1.nip.io:8080
```

## Application - GuestBook
The [GuestBook application](/apps/guestbook) is based on the example from the K8s [documentation](https://github.com/kubernetes/kubernetes/tree/release-1.2/examples/guestbook/).

To deploy the application:
```sh
$ kubectl create -f app/guestbook/redis.yml    # create redis master service and deployment
$ kubectl create -f app/guestbook/frontend.yml # create the guestbook app
```

To access the application, use your browser to navigate to http://<GUESTBOOK_EXTERNAL_IP> where `GUESTBOOK_EXTERNAL_IP` can be retrieved using `$ kubectl describe services frontend`.

To remove the application:
```sh
$ ./apps/guestbook/cleanup.sh
```

## LICENSE

This project is under Apache v2 License. See the [LICENSE](LICENSE) file for the full license text.
