# Builds the docker image used to build the kernel
.PHONY: build-image
build-image:
	cd builder && docker build . -t pve-kernel-builder:current -t kriansa/pve-kernel-builder:current

.PHONY: publish-image
publish-image:
	docker push kriansa/pve-kernel-builder:current

.PHONY: pull-image
pull-image:
	docker pull kriansa/pve-kernel-builder:current

# Open up a new terminal with the build environment set up
.PHONY: build-env
build-env:
	bin/build --shell

# Runs a container with the default build action
.PHONY: build
build:
	bin/build

.PHONY: deploy
deploy:
	cd ops/terraform && terraform-auto \
		--environment-file="../../.env" \
		--backend-template-file="backend.tf-template" \
		apply $(args)
