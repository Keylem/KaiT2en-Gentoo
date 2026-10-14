#!/usr/bin/env bash
# Portage compatibility shim: install-dsp.sh (no /usr/local, DKMS or Fedora actions)
set -euo pipefail
PACKAGES=( "app-misc/t2-dsp" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
