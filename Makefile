SHELL := /bin/bash

FE_BIN ?= $(CURDIR)/.contest-tools/fe_linux_amd64
export FE_BIN

.PHONY: help setup verify demo

help:
	@printf '%s\n' \
	  'DualClear developer commands:' \
	  '  make setup   Download and verify Fe 26.5.0 locally' \
	  '  make verify  Format/check/build/test EVM and native targets' \
	  '  make demo    Run the cross-backend golden demonstration'

setup:
	./scripts/install-fe.sh

verify: setup
	./scripts/verify.sh

demo: setup
	./scripts/demo.sh
