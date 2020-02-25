# ---
# This Makefile is intended to be used on the Development environment
# Commands described here base upon the fact that they're being run on a developer machine
# ---

DOCKER_IMAGE_NAME:=$(shell grep -E '^DOCKER_IMAGE_NAME=' .env | \
	 awk -F = '{ print $$2 }' | grep -Eo '[-[:alnum:]./_]+')

# Builds the docker image used to build the kernel
.PHONY: build-image
build-image:
	@docker build . -t ${DOCKER_IMAGE_NAME}:current

.PHONY: publish-image
publish-image:
	@docker push ${DOCKER_IMAGE_NAME}:current

.PHONY: pull-image
pull-image:
	@docker pull ${DOCKER_IMAGE_NAME}:current

# Open up a new terminal with the build environment set up
.PHONY: build-env
build-env:
	@source ./.env && docker run --rm --name "kernel-builder" \
		-v "$(shell pwd)/src:/src" \
		-v "${HOME}/.aws/credentials:/root/.aws/credentials" \
		-e "AWS_PROFILE" \
		-e "AWS_DEFAULT_REGION" \
		-e "REPO_S3_BUCKET" \
		-e "REPO_S3_APT_PATH" \
		-it \
		${DOCKER_IMAGE_NAME}:current /bin/bash

.PHONY: deploy
deploy:
	@cd ops/terraform && terraform-auto \
		--environment-file="../../.env" \
		--backend-template-file="backend.tf-template" \
		apply $(args)
