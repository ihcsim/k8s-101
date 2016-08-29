.PHONY: droplet

droplet:
	coreos/droplet.sh

cacert:
	cfssl gencert -initca coreos/tls/ca-csr.json | cfssljson -bare ca -

droplet-cert:
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=coreos/tls/ca-config.json -profile=client-server ${DROPLET_CERT_CONFIG_FILE} | cfssljson -bare coreos
	chmod 0644 coreos-key.pem
	scp ca.pem coreos-key.pem coreos.pem core@${DROPLET_PUBLIC_IP}:

cfssl:
	go get -u github.com/cloudflare/cfssl/cmd/...

clean:
	coreos/cleanup.sh
