# Copyright 2016 The Kubernetes Authors All rights reserved.
# #
# # Licensed under the Apache License, Version 2.0 (the "License");
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# #
# #     http://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an "AS IS" BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.

KEY_OUT ?= dev.key
CERT_OUT ?= dev.crt
SECRET_OUT ?= secret.json
SECRET_NAME ?= svcsecret
SVC_NAME ?= my-svc

keys:
	# The CName used here is specific to the service specified in yaml.
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(KEY_OUT) -out $(CERT_OUT) -subj "/CN=$(SVC_NAME)/O=$(SVC_NAME)"
		
secret:
	godep go run make_secret.go -name $(SECRET_NAME) -crt $(CERT_OUT) -key $(KEY_OUT) > $(SECRET_OUT)

clean:
	rm $(KEY_OUT)
	rm $(CERT_OUT)
