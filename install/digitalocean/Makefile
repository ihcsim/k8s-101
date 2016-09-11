.PHONY: etcd k8s-master k8s-nodes

etcd:
	etcd/droplet.sh

k8s-master:
	k8s/master/droplet.sh

k8s-ssl:
	mkdir -p ssl
	openssl req -x509 -newkey rsa:4096 -keyout ssl/k8s.pem -out ssl/k8s-cert.pem -nodes

k8s-nodes:
	k8s/nodes/droplet.sh

clean:
	./cleanup.sh
