#!/usr/bin/env bash
# Portage compatibility shim: install-apps.sh (no /usr/local, DKMS or Fedora actions)
set -euo pipefail
PACKAGES=( "app-misc/kait2en-assets" "app-misc/t2-fan-control" "app-misc/t2-smc-control" "app-misc/t2-power-explorer" "app-misc/t2-force-click" "app-misc/t2-zone-power" "app-misc/t2-journal" "app-misc/t2-power-tune" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
