#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly FE_VERSION="26.5.0"
readonly FE_COMMIT_SHORT="3dab95f"
readonly FE_SHA256="3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0"
readonly DEFAULT_URL="https://github.com/argotorg/fe/releases/download/v${FE_VERSION}/fe_linux_amd64"
readonly FE_URL="${FE_DOWNLOAD_URL:-$DEFAULT_URL}"
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"

mkdir -p -- "$(dirname -- "$FE_BIN")"

if [[ -f "$FE_BIN" ]] && printf '%s  %s\n' "$FE_SHA256" "$FE_BIN" | sha256sum -c - >/dev/null 2>&1; then
    chmod u+x -- "$FE_BIN"
    "$FE_BIN" --version
    exit 0
fi

tmp_file="$(mktemp "${FE_BIN}.download.XXXXXX")"
trap 'rm -f -- "$tmp_file"' EXIT

curl --proto '=https' --tlsv1.2 --fail --location --retry 3 \
    --output "$tmp_file" "$FE_URL"
printf '%s  %s\n' "$FE_SHA256" "$tmp_file" | sha256sum -c -
chmod u+x -- "$tmp_file"

version_output="$("$tmp_file" --version)"
expected_version="fe ${FE_VERSION} (${FE_COMMIT_SHORT})"
if [[ "$version_output" != "$expected_version" ]]; then
    printf 'Unexpected Fe version: %s (expected %s)\n' \
        "$version_output" "$expected_version" >&2
    exit 1
fi

mv -f -- "$tmp_file" "$FE_BIN"
trap - EXIT
printf 'Installed %s at %s\n' "$version_output" "$FE_BIN"
