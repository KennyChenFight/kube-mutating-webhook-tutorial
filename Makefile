IMAGE_REPO ?= docker.io/kennychenfight
IMAGE_NAME ?= sidecar-injector
IMAGE_TAG ?= $(shell date +v%Y%m%d)

.PHONY: all
all: build image

.PHONY: build
build:
	@echo "Building the $(IMAGE_NAME) binary..."
	@CGO_ENABLED=0 go build -o build/_output/bin/$(IMAGE_NAME) ./cmd/

.PHONY: build-linux
build-linux:
	@echo "Building the $(IMAGE_NAME) binary for Docker (linux)..."
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o build/_output/linux/bin/$(IMAGE_NAME) ./cmd/

.PHONY: image
image: build-image push-image

.PHONY: build-image
build-image: build-linux
	@echo "Building the docker image: $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)..."
	@docker build -t $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) -f build/Dockerfile .

.PHONY: push-image
push-image: build-image
	@echo "Pushing the docker image for $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) and $(IMAGE_REPO)/$(IMAGE_NAME):latest..."
	@docker tag $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_REPO)/$(IMAGE_NAME):latest
	@docker push $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	@docker push $(IMAGE_REPO)/$(IMAGE_NAME):latest

.PHONY: clean
clean:
	@rm -rf build/_output

