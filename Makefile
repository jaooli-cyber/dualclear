SHELL := /bin/bash

FE_BIN ?= $(CURDIR)/.contest-tools/fe_linux_amd64
export FE_BIN

.NOTPARALLEL: candidate release-evidence

.PHONY: help setup verify demo test-cli metrics abi-check candidate release-evidence

help:
	@printf '%s\n' \
	  'DualClear developer commands:' \
	  '  make setup     Download and verify Fe 26.5.0 locally' \
	  '  make verify    Format/check/build/test EVM, native, and CLI' \
	  '  make demo      Run the cross-backend golden demonstration' \
	  '  make test-cli  Run native CLI boundary and parser tests' \
	  '  make metrics   Rebuild and measure EVM artifacts' \
	  '  make abi-check Verify the frozen ABI and raw v1 golden' \
	  '  make candidate Run every submission-candidate verification gate' \
	  '  make release-evidence EVIDENCE_TAG=fe-013-submission-v1'

setup:
	./scripts/install-fe.sh

verify: setup
	./scripts/verify.sh

demo: setup
	./scripts/demo.sh

test-cli: setup
	./scripts/test-cli.sh

metrics: setup
	./scripts/metrics.sh

abi-check: metrics
	./scripts/check-abi.sh

candidate: verify abi-check demo

release-evidence:
	@test -n "$(EVIDENCE_TAG)" || { \
		echo "usage: make release-evidence EVIDENCE_TAG=fe-013-submission-v1" >&2; exit 1; }
	EVIDENCE_PRE_TAG="$(EVIDENCE_PRE_TAG)" \
		./scripts/release-evidence.sh "$(EVIDENCE_TAG)"
