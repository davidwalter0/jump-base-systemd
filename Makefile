.PHONY: push yaml

export USER_HOME=${HOME}
export JUMP_USER=jump
export DockerUser=davidwalter
export version=$$(cat .version)

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


image: Makefile systemd/Dockerfile.tmpl .version .dep/yaml .dep/apply
	cd systemd; docker build --tag=davidwalter/debian-stretch-slim-$(notdir $(PWD)):latest .
	touch image

tag: image .version
	docker tag davidwalter/debian-stretch-slim-$(notdir $(PWD)):latest davidwalter/debian-stretch-slim-$(notdir $(PWD)):$$(cat .version)
	touch tag

push: tag .version
	docker push davidwalter/debian-stretch-slim-$(notdir $(PWD)):latest
	docker push davidwalter/debian-stretch-slim-$(notdir $(PWD)):$$(cat .version)
clean:
	rm .dep/*
