# Copyright 2018 David Walter.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY: install clean build yaml appl get push tag tag-push info
# To enable kubernetes commands a valid configuration is required
deploy_list:=$(patsubst %.tmpl,%,$(wildcard systemd/*.tmpl))
export GOPATH=/go
export kubectl=${GOPATH}/bin/kubectl  --kubeconfig=${PWD}/cluster/auth/kubeconfig
SHELL=/bin/bash
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
CURRENT_DIR := $(notdir $(patsubst %/,%,$(dir $(MAKEFILE_DIR))))
export DIR=$(MAKEFILE_DIR)
export APPL=$(notdir $(PWD))
export IMAGE=$(notdir $(PWD))
# extract tag from latest commit, use tag for version
export gittag=$$(git tag -l --contains $(git log --pretty="format:%h"  -n1))
export TAG=$(shell if git diff --quiet --ignore-submodules HEAD && [[ -n $(gittag) ]]; then echo $(gittag); else echo "canary"; fi)

include Makefile.defs

all: info

info: 
	@echo $(info)

etags:
	etags $(depends) $(build_deps)

.dep:
	mkdir -p .dep
	touch .dep --reference=Makefile

.dep/image-$(DOCKER_USER)-$(IMAGE)-latest: .dep $(wildcard systemd/Dockerfile systemd/*.tmpl systemd/systemd-user-sessions.service)
	cd systemd; \
	docker build --tag=$(DOCKER_USER)/$(IMAGE):latest .
	touch $@ 

tag: info .dep .dep/tag-$(DOCKER_USER)-$(IMAGE)-$(TAG)
	@echo $(info)

.dep/tag-$(DOCKER_USER)-$(IMAGE)-$(TAG): .dep/image-$(DOCKER_USER)-$(IMAGE)-latest
	docker tag $(DOCKER_USER)/$(IMAGE):latest \
	$(DOCKER_USER)/$(IMAGE):$${TAG}
	touch $@ 

push: info .dep .dep/push-$(DOCKER_USER)-$(IMAGE)-latest

.dep/push-$(DOCKER_USER)-$(IMAGE)-latest: .dep/image-$(DOCKER_USER)-$(IMAGE)-latest
	docker push $(DOCKER_USER)/$(IMAGE):latest
	touch $@

tag-push: info .dep/tag-$(DOCKER_USER)-$(IMAGE)-$(TAG) .dep/tag-push-$(DOCKER_USER)-$(IMAGE)-$(TAG)

.dep/tag-push-$(DOCKER_USER)-$(IMAGE)-$(TAG): .dep/image-$(DOCKER_USER)-$(IMAGE)-latest
	docker push $(DOCKER_USER)/$(IMAGE):$(TAG)
	touch $@

yaml: info .dep .dep/yaml-$(DOCKER_USER)-$(IMAGE)-$(TAG)

.dep/yaml-$(DOCKER_USER)-$(IMAGE)-$(TAG): .dep $(wildcard systemd/*.tmpl)
	@for file in $(deploy_list); do echo $${file}; done
	for file in $(wildcard systemd/*.tmpl); do echo "${GOPATH}/bin/applytmpl < $${file} > $${file%.tmpl}"; done
	for file in $(wildcard systemd/*.tmpl); do ${GOPATH}/bin/applytmpl < $${file} > $${file%.tmpl}; done
	@echo "$@ build complete $^"
	touch $@

delete: .dep/delete

.dep/delete: yaml
	$(kubectl) delete ds/$(APPL) || true

deploy: info .dep/deploy

.dep/deploy: .dep yaml
	$(kubectl) apply -f systemd/deployment.yaml

get: info .dep 

.dep/get: .dep yaml
	$(kubectl) get -f systemd/deployment.yaml

clean: .dep bin 
	@if [[ -d "bin" ]]; then rmdir bin; fi
	rm -f .dep/*

bin:
	mkdir -p bin
