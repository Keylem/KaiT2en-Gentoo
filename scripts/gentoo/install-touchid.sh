#!/usr/bin/env bash
# Portage compatibility shim: install-touchid.sh (no /usr/local, DKMS or Fedora actions)
set -euo pipefail
PACKAGES=( "app-misc/t2-services-common" "app-misc/t2-touchid" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
