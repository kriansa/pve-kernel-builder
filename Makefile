# Builds the docker image used to build the kernel
image:
	cd builder && docker build . -t pve-kernel-builder:current -t kriansa/pve-kernel-builder:current

publish-image:
	docker push kriansa/pve-kernel-builder:current

# Open up a new container with the build environment set up
build-env:
	docker run --rm -it -v "$(shell pwd)/patches:/patches" -v "$(shell pwd)/src:/src" pve-kernel-builder:current /bin/bash

# Runs the docker image with the default build action
build:
	docker run --rm -it -v "$(shell pwd)/patches:/patches" -v "$(shell pwd)/src:/src" pve-kernel-builder:current
