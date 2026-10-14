#!/usr/bin/env bash
# Portage compatibility shim: install-dependencies.sh (no /usr/local, DKMS or Fedora actions)
set -euo pipefail
PACKAGES=( "app-misc/kait2en" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
