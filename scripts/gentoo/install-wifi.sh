#!/usr/bin/env bash
# Install the opt-in Wi-Fi recovery extractor through Gentoo Portage only.
set -euo pipefail
PACKAGES=( "app-misc/kait2en-wifi-tools" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
