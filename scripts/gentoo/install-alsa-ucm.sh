#!/usr/bin/env bash
# Portage compatibility shim: install-alsa-ucm.sh (no /usr/local, DKMS or Fedora actions)
set -euo pipefail
PACKAGES=( "app-misc/t2-alsa-ucm" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
