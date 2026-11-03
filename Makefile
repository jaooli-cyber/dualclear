SHELL := /bin/bash

FE_BIN ?= $(CURDIR)/.contest-tools/fe_linux_amd64
export FE_BIN

.PHONY: help setup verify demo test-cli

help:
	@printf '%s\n' \
	  'DualClear developer commands:' \
	  '  make setup     Download and verify Fe 26.5.0 locally' \
	  '  make verify    Format/check/build/test EVM, native, and CLI' \
	  '  make demo      Run the cross-backend golden demonstration' \
	  '  make test-cli  Run native CLI boundary and parser tests'

setup:
	./scripts/install-fe.sh

verify: setup
	./scripts/verify.sh

demo: setup
	./scripts/demo.sh

test-cli: setup
	./scripts/test-cli.sh
