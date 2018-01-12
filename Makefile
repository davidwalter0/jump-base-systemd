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



.PHONY: push yaml

# export PUBLIC_KEY_FILE=$(HOME)/.ssh/id_rsa.pub
# export JUMP_USER=jump
# export DOCKER_USER=$(DOCKER_USER)

include Makefile.defs
export version=$$(cat .version)

ifeq ($(DOCKER_USER),)
$(warning $(text))
$(error environment variable DOCKER_USER hub.docker.com login userid not set)
endif

ifeq ($(PUBLIC_KEY_FILE),)
$(warning $(text))
$(error environment variable PUBLIC_KEY_FILE not set)
endif

ifeq ($(JUMP_USER),) 

$(warning $(text) $(jumptext))

$(error environment variable JUMP_USER is not set)
endif

apply_list:=$(patsubst %.tmpl,%,$(wildcard systemd/*.tmpl))

all: yaml apply image push

.dep:
	mkdir -p .dep

yaml: .dep .dep/yaml $(wildcard systemd/*.tmpl)

.dep/yaml: .dep $(wildcard systemd/*.tmpl)
	@for file in $(apply_list); do echo $${file}; done
	for file in $(wildcard systemd/*.tmpl); do echo "${GOPATH}/bin/applytmpl < $${file} > $${file%.tmpl}"; done
	@echo "$@ build complete $^"
	touch .dep/yaml

apply: yaml .dep .dep/apply

.dep/apply: yaml .dep $(wildcard systemd/*.tmpl)
	for file in */*.tmpl; do ${GOPATH}/bin/applytmpl < $${file} > $${file%.tmpl}; done
	touch .dep/apply

.dep/image: Makefile systemd/Dockerfile.tmpl .version .dep/yaml .dep/apply
	cd systemd; docker build --tag=$(DOCKER_USER)/$(notdir $(PWD)):latest .
	touch .dep/image

image: .dep/image

tag: image .version
	docker tag $(DOCKER_USER)/$(notdir $(PWD)):latest $(DOCKER_USER)/$(notdir $(PWD)):$$(cat .version)
	touch tag

push: tag .version
	docker push $(DOCKER_USER)/$(notdir $(PWD)):latest
	docker push $(DOCKER_USER)/$(notdir $(PWD)):$$(cat .version)
clean:
	rm .dep/*
