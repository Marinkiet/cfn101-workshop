SHELL := /bin/bash

.PHONY : help init test lint nag release clean
.DEFAULT: help

VENV_NAME ?= venv
PYTHON ?= $(VENV_NAME)/bin/python
AWS_CLI = $(VENV_NAME)/bin/aws

ifneq ("$(wildcard $(CONFIG_FILE))","")
	include $(CONFIG_FILE)
endif

help:
	@echo "help	get the full command list"
	@echo "init	create VirtualEnv and install libraries"
	@echo "test	run pre-commit checks"
	@echo "lint	GitHub actions cfn-lint test"
	@echo "nag	GitHub actions cfn-nag test"
	@echo "version	[part=major||minor||patch] bump version and tag release (make version part=patch)"
	@echo "clean	delete VirtualEnv and installed libraries"

# Install VirtualEnv and dependencies
init: $(VENV_NAME) pre-commit

$(VENV_NAME): $(VENV_NAME)/bin/activate

$(VENV_NAME)/bin/activate: requirements.txt
	test -d $(VENV_NAME) || virtualenv -p python3 $(VENV_NAME)
	$(PYTHON) -m pip install -U pip
	$(PYTHON) -m pip install -Ur requirements.txt
	touch $(VENV_NAME)/bin/activate

pre-commit:
	. $(VENV_NAME)/bin/activate && $(VENV_NAME)/bin/pre-commit install

# Cleanup VirtualEnv
clean:
	rm -rf $(VENV_NAME)
	find . -iname "*.pyc" -delete

# Tests
test:
	$(VENV_NAME)/bin/pre-commit run --all-files

test-cfn-lint:
	cfn-lint cfn-lint code/solutions/**/*.yaml --ignore-templates code/solutions/policy-as-code-with-guard/example_bucket_tests.yaml

test-cfn-nag:
	cfn_nag_scan --input-path code/solutions --ignore-fatal

version:
	@bumpversion $(part) --allow-dirty

release: version
	@TAG_VERSION=$(shell bumpversion --dry-run --list .bumpversion.cfg --allow-dirty | grep current_version | sed s/'^.*='//); \
		git push origin "v$${TAG_VERSION}"