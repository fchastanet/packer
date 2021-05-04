# delete default suffixes
.SUFFIXES:
.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL   := help
THIS_MAKEFILE   :=$(MAKEFILE_LIST)

SHELL           := /bin/bash
SHELL_COMMAND   := bash

THIS_DIR 			               := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PACKER_FILES                 := $(shell find $(THIS_DIR) -maxdepth 1 -type f -name "*.json")
SCRIPTS_COMMON_FILES         := $(shell find "$(THIS_DIR)/scripts" -type f  | sort)
SCRIPTS_DESKTOP_FILES        := $(shell find "$(THIS_DIR)/scripts-desktop" -type f | sort)

# you can override these variables by launching make like this
# $ make BOX_VERSION=1.0.0 HEADLESS=false USER="customUser" BOX="box-bionic64" CLOUD_TOKEN="verysecrettoken" build
# use this one if your vagrant cloud token is specifed in the file vagrant.token
# $ make BOX_VERSION=1.0.0 HEADLESS=false USER="customUser" BOX="box-bionic64" build
BOX_VERSION     ?= 4.0.0
HEADLESS        ?= true
CLOUD_TOKEN     ?= $(shell [[ -f vagrant.token ]] && cat vagrant.token || echo "no key provided")
PROVIDER        ?= virtualbox
# user for vagrant account
USER            ?= fchastanet
BOX			        ?= ubuntu21.04
DESKTOP		      ?= lxde
VM_NAME         ?= box-dev-env
BOX_FILE_PREFIX := output-virtualbox

# UBUNTU iso information
UBUNTU_VERSION      := ubuntu-21.04
BASE_UBUNTU_ISO_URL := https://releases.ubuntu.com/21.04
UBUNTU_ISO_NAME     := ubuntu-21.04-live-server-amd64.iso
UBUNTU_ISO_URL      := iso/$(UBUNTU_ISO_NAME)
UBUNTU_ISO_CHECKSUM := e4089c47104375b59951bad6c7b3ee5d9f6d80bfac4597e43a716bb8f5c1f3b0

# dependencies versions
DOCKER_COMPOSE_VERSION := 1.28.6
NVM_VERSION := 0.38.0

.PHONY: help
help: ## Prints this help
help:
	@grep -E '(^[0-9a-zA-Z_-]+:.*?##.*$$)|(^##)' $(THIS_MAKEFILE) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

#-----------------------------------------------------------------------------
# BUILD DEPENDENCIES

$(HOME)/.ssh/id_rsa:
	@$(error "File '$@' does not exist! Exiting...")

$(HOME)/.ssh/id_rsa.pub:
	@$(error "File '$@' does not exist! Exiting...")

.PHONY: check_ssh_files
check_ssh_files: $(HOME)/.ssh/id_rsa $(HOME)/.ssh/id_rsa.pub

.PHONY: check_dependencies_packer_mandatory
check_dependencies_packer_mandatory: scripts-vagrant/makefile-check-dependencies.sh
	@$(SHELL_COMMAND) scripts-vagrant/makefile-check-dependencies.sh "packer-mandatory"

.PHONY: check_dependencies
check_dependencies: check_ssh_files scripts-vagrant/makefile-check-dependencies.sh
	@$(SHELL_COMMAND) scripts-vagrant/makefile-check-dependencies.sh

#-----------------------------------------------------------------------------
# Build
FULL_DEPS := ubuntu.pkr.hcl http/user-data
FULL_DEPS += $(SCRIPTS_COMMON_FILES)
FULL_DEPS += $(SCRIPTS_DESKTOP_FILES)
FULL_DEPS += Vagrantfile.box.template
$(BOX_FILE_PREFIX)-gnome/$(UBUNTU_VERSION)-$(BOX_VERSION)-gnome.box: $(FULL_DEPS)
	rm -Rf $(BOX_FILE_PREFIX)-gnome "logs/00-imagePacker-gnome.log"
	./scripts-vagrant/makefile-pack-box.sh "$<" gnome "logs/00-imagePacker-gnome.log"

$(BOX_FILE_PREFIX)-lxde/$(UBUNTU_VERSION)-$(BOX_VERSION)-lxde.box: $(FULL_DEPS)
	rm -Rf $(BOX_FILE_PREFIX)-lxde "logs/00-imagePacker-lxde.log"
	./scripts-vagrant/makefile-pack-box.sh "$<" lxde "logs/00-imagePacker-lxde.log"

$(BOX_FILE_PREFIX)-serverX11/$(UBUNTU_VERSION)-$(BOX_VERSION)-serverX11.box: $(FULL_DEPS)
	rm -Rf $(BOX_FILE_PREFIX)-serverX11 "logs/00-imagePacker-serverX11.log"
	./scripts-vagrant/makefile-pack-box.sh "$<" serverX11 "logs/00-imagePacker-serverX11.log"

.PHONY: build
build: ## build all images using intermediate stages
build: check_dependencies_packer_mandatory $(BOX_FILE_PREFIX)-$(DESKTOP)/$(UBUNTU_VERSION)-$(BOX_VERSION)-$(DESKTOP).box
	@tail -n 1 logs/box-$(BOX_VERSION)-$(DESKTOP)-created
	$(info build files are up to date)

#-----------------------------------------------------------------------------
# DEPLOY

.PHONY: deploy-box
deploy-box: $(BOX_FILE_PREFIX)-$(DESKTOP)/$(UBUNTU_VERSION)-$(BOX_VERSION)-$(DESKTOP).box ImageDescription.md ImageDescription-$(DESKTOP).md
deploy-box: $(BOX_FILE_PREFIX)-$(DESKTOP)/$(UBUNTU_VERSION)-$(BOX_VERSION)-$(DESKTOP).deployed
	@$(SHELL_COMMAND) scripts-vagrant/makefile-vagrant-deploy.sh \
		"$(USER)" "$(BOX)-$(DESKTOP)" "$(BOX_VERSION)" \
		"ImageDescription.md" "ImageDescription-$(DESKTOP).md" \
		"$(CLOUD_TOKEN)" "$(BOX_FILE_PREFIX)-$(DESKTOP)" \
		"$(UBUNTU_VERSION)-$(BOX_VERSION)-$(DESKTOP).box" "$(DESKTOP)"

.PHONY: deploy-s3
deploy-s3:
	@$(SHELL_COMMAND) scripts-vagrant/makefile-vagrant-deploy-s3.sh \
		"$(USER)" \
		"$(BOX_FILE_PREFIX)-$(DESKTOP)/$(UBUNTU_VERSION)-$(BOX_VERSION)-$(DESKTOP).box" \
		"$(S3_BUCKET_URL)"

$(BOX_FILE_PREFIX)-gnome/$(UBUNTU_VERSION)-$(BOX_VERSION)-gnome.deployed: DESKTOP=gnome
$(BOX_FILE_PREFIX)-gnome/$(UBUNTU_VERSION)-$(BOX_VERSION)-gnome.deployed: deploy-box

$(BOX_FILE_PREFIX)-lxde/$(UBUNTU_VERSION)-$(BOX_VERSION)-lxde.deployed: DESKTOP=lxde
$(BOX_FILE_PREFIX)-lxde/$(UBUNTU_VERSION)-$(BOX_VERSION)-lxde.deployed: deploy-box

$(BOX_FILE_PREFIX)-serverX11/$(UBUNTU_VERSION)-$(BOX_VERSION)-serverX11.deployed: DESKTOP=serverX11
$(BOX_FILE_PREFIX)-serverX11/$(UBUNTU_VERSION)-$(BOX_VERSION)-serverX11.deployed: deploy-box

BOX_TO_DEPLOY :=
BOX_TO_DEPLOY += $(BOX_FILE_PREFIX)-gnome/$(UBUNTU_VERSION)-$(BOX_VERSION)-gnome.deployed
BOX_TO_DEPLOY += $(BOX_FILE_PREFIX)-lxde/$(UBUNTU_VERSION)-$(BOX_VERSION)-lxde.deployed
BOX_TO_DEPLOY += $(BOX_FILE_PREFIX)-serverX11/$(UBUNTU_VERSION)-$(BOX_VERSION)-serverX11.deployed
.PHONY: deploy
deploy: ## build images and try to deploy it if vagrant token is provided
deploy: build  $(BOX_TO_DEPLOY)
#-----------------------------------------------------------------------------
# START

.PHONY: start
start: ## start the project using Vagrantfile (means you've first called make first-start or first-start-local before)
start:
	@-if [[ ! -f Vagrantfile ]]; then echo "before you should run 'make first-start' or 'make first-start-local'"; exit 1; fi
	vagrant up

.PHONY: first-start
first-start: ## start the project by downloading the box from vagrant cloud
first-start: ##       use `DESKTOP=lxde make first-start` to target lxde vm instead of gnome
first-start: check_dependencies Vagrantfile
	@if [[ ! -z $(S3_BUCKET_URL) ]]; then $(SHELL_COMMAND) scripts-vagrant/makefile-vagrant-download-s3.sh \
		"$(USER)" \
		"$(BOX_FILE_PREFIX)-$(DESKTOP)/$(UBUNTU_VERSION)-$(BOX_VERSION)-$(DESKTOP).box" \
		"$(S3_BUCKET_URL)" ; fi
	vagrant up

Vagrantfile: Vagrantfile.template
	[[ -f Vagrantfile ]] && (cp -v Vagrantfile Vagrantfile.bak && echo "Upgraded Vagrantfile - backup created") || true
	cp Vagrantfile.template Vagrantfile
	sed -i -e "s/@@@VM_NAME@@@/$(VM_NAME)-$(DESKTOP)/g" Vagrantfile || true
	sed -i -e "s#@@@VAGRANT_BOX@@@#$(USER)/$(BOX)-$(DESKTOP)-$(BOX_VERSION)#g" Vagrantfile || true
	sed -i -e "s#@@@VAGRANT_BOX_VERSION@@@#$(BOX_VERSION)#g" Vagrantfile || true

.PHONY: first-start-local
first-start-local: ## start the project by using the box generated locally by packer
first-start-local: ##       use `DESKTOP=lxde make first-start-local` to target lxde vm instead of gnome
first-start-local: check_dependencies_packer_mandatory Vagrantfile
	@if [ ! -f "$(BOX_FILE_PREFIX)-$(DESKTOP)/$(UBUNTU_VERSION)-$(BOX_VERSION)-$(DESKTOP).box" ]; then (>&2 echo "before you should run 'make build'") && exit 1; fi
	./scripts-vagrant/makefile-first-start-local.sh

#-----------------------------------------------------------------------------
# Independent install
manual-install: $(SCRIPTS_COMMON_FILES) $(SCRIPTS_DESKTOP_FILES) scripts-common/cleanup.sh scripts-vagrant/vm-bootstrap.sh
	USERNAME=$(shell id -un) GROUPNAME=$(shell id -gn) DESKTOP=$(DESKTOP) USERHOME=$(HOME)  ./scripts-vagrant/manual-install.sh $^

#-----------------------------------------------------------------------------
# TESTS

vendor:
	@mkdir -p vendor

vendor/bats/bin/bats: vendor
	./scripts-vagrant/bats-install.sh

vendor/bash-tools/bash-framework/_bootstrap.sh: vendor
	git clone git@github.com:fchastanet/bash-tools.git vendor/bash-tools

test-box-gnome:
	scripts-vagrant/makefile-test-box.sh "gnome" "00-Vagrantfile.template" "00-box-tests.bats" "$(BOX_VERSION)"
	scripts-vagrant/makefile-test-box.sh "gnome" "01-Vagrantfile.template" "01-box-tests.bats" "$(BOX_VERSION)"

test-box-lxde:
	scripts-vagrant/makefile-test-box.sh "lxde" "00-Vagrantfile.template" "00-box-tests.bats" "$(BOX_VERSION)"
	scripts-vagrant/makefile-test-box.sh "lxde" "01-Vagrantfile.template" "01-box-tests.bats" "$(BOX_VERSION)"

tests/01-Vagrantfile:
	@cp Vagrantfile.template tests/01-Vagrantfile.template
	@sed -i \
		-e "s/disk_variant = 'FIXED'/disk_variant = 'Standard'/g" \
		-e "s#disk_filename =.*#disk_filename = './test_userData.vdi'#g" \
		-e "/VAGRANT_BOX_VERSION = .*/d" \
		-e "s/VM_NAME = .*/VM_NAME = \"vm-test-@@@BOX_TESTED@@@-$(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)\"/g" \
		-e "/virtualbox.vm.box_version.*/d" \
		-e '/config.vm.network "forwarded_port".*/d' \
		-e 's#File.dirname(__FILE__) + "#"..#g' \
		-e 's/v.gui = true/v.gui = false/g' \
		tests/01-Vagrantfile.template

.PHONY: tests
tests: vendor/bats/bin/bats vendor/bash-tools/bash-framework/_bootstrap.sh tests/01-Vagrantfile
tests: test-box-$(DESKTOP)

#-----------------------------------------------------------------------------
# CLEAN

.PHONY: clean
clean: ## clean build files
clean:
	@$(info clean build files)
	rm -f logs/*
	rm -Rf output-virtualbox-*

.PHONY: clean-hard
clean-hard: ## clean artifacts, cache, build files
clean-hard: clean
	vagrant destroy
	rm -f iso/*
	rm -Rf packer_cache/*
	rm -Rf .vagrant
	rm -f Vagrantfile Vagrantfile.box
	rm -f vagrant.token
