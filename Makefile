all: build
PACKAGE=github.com/rapenchukd/SORdid

ARCH?=amd64
GOLANG_VERSION?=1.13.8
CONTAINER_BUILD_IMAGE?=golang:$(GOLANG_VERSION)
REPO_DIR:=$(shell pwd)
GOPATH?=$(shell go env GOPATH)
DOCKER_RUN=docker run --rm -i $(TTY) -v $(TEMP_DIR):/build -v $(REPO_DIR):/go/src/$(PACKAGE):z -w /go/src/$(PACKAGE) -e GOARCH=$(ARCH)
DOCKER_IMAGE?=rapenchukd/SORdid
MYVERSION?=v0.0.1
SCRATCH_IMAGE?=scratch
SCRATCH_TAG?=""
MOD=go mod

ifneq ("$(http_proxy)", "")
PROXY_VARS=http_proxy=$(http_proxy) https_proxy=$(http_proxy)
DOCKER_RUN += -e http_proxy=$(http_proxy) $(CONTAINER_BUILD_IMAGE)
gitconfig:
	# Pull proxies for building if appropriate, be nice to the corp folk
	git config http.proxy $(http_proxy)
	git config https.proxy $(http_proxy)
	git config url.https://github.com/.insteadof git://github.com/
else
DOCKER_RUN += $(CONTAINER_BUILD_IMAGE)
gitconfig:
	@echo no gitconfig
endif

ifndef TEMP_DIR
TEMP_DIR:=$(shell mktemp -d /tmp/SORdid.XXXXXX)
endif

TTY=
ifeq ($(shell [ -t 0 ] && echo 1 || echo 0), 1)
	TTY=-t
endif

vendor:
	$(PROXY_VARS) $(MOD) vendor

build/SORdid: clean vendor
	GOARCH=$(ARCH) go build -o build/SORdid $(PACKAGE)/app/SORdid

container: 
	# Run the build in a container in order to have reproducible builds
	$(DOCKER_RUN) make build/SORdid
	docker build . --pull -t $(DOCKER_IMAGE):$(MYVERSION) -t $(DOCKER_IMAGE):latest --build-arg IMAGE=$(SCRATCH_IMAGE) --build-arg TAG=$(SCRATCH_TAG)
	docker build . -f Dockerfile.vendor -t $(DOCKER_IMAGE):$(MYVERSION)-vendor -t $(DOCKER_IMAGE):latest-vendor --build-arg IMAGE=$(SCRATCH_IMAGE) --build-arg TAG=$(SCRATCH_TAG)

pushcontainer:
	docker push $(DOCKER_IMAGE):$(MYVERSION)
	docker push $(DOCKER_IMAGE):latest
	docker push $(DOCKER_IMAGE):$(MYVERSION)-vendor
	docker push $(DOCKER_IMAGE):latest-vendor
	docker rmi $(DOCKER_IMAGE):$(MYVERSION)
	docker rmi $(DOCKER_IMAGE):latest
	docker rmi $(DOCKER_IMAGE):$(MYVERSION)-vendor
	docker rmi $(DOCKER_IMAGE):latest-vendor

test: clean vendor
	CGO_ENABLED=1 go test -race -v --cover ./...

clean:
	rm -rf build

gofmt:
	@hack/gofmt.sh

lint: clean
	CGO_ENABLED=0 golint -set_exit_status $(shell go list ./...)

.PHONY: all build gofmt lint lintcontainer pushcontainer testcontainer container clean test
