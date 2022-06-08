IMAGE_NAME := prefect-orion
IMAGE_TAG := beta6
IMAGE := ${IMAGE_NAME}:${IMAGE_TAG}
IMAGE_HASH := $(shell command docker images -q ${IMAGE} 2> /dev/null)


.PHONY: docker_image_cond
docker_image_cond:
ifeq ($(IMAGE_HASH),)
docker_image_cond: docker
endif


.PHONY: docker
docker:
	@echo "building docker image ...";
	docker build --no-cache -f Dockerfile -t ${IMAGE} .


.PHONY: register-test-flow
register-test-flow: docker_image_cond
	docker-compose exec prefect-server /bin/bash -c 'prefect deployment create /flows/test_flow.py'
