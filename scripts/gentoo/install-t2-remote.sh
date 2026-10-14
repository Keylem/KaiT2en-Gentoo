#!/usr/bin/env bash
# Portage compatibility shim: install-t2-remote.sh (no /usr/local, DKMS or Fedora actions)
set -euo pipefail
PACKAGES=( "app-misc/t2-services-common" "app-misc/t2-ave" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
