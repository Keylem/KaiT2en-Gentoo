#!/usr/bin/env bash
# Portage compatibility shim: install-dkms-modules.sh (no /usr/local, DKMS or Fedora actions)
set -euo pipefail
PACKAGES=( "sys-kernel/kait2en-t2bce-stack" "sys-kernel/kait2en-t2smc" "sys-kernel/kait2en-t2sbs" "sys-kernel/kait2en-t2sep" "sys-kernel/kait2en-t2gmux" "sys-kernel/kait2en-t2bdrm" "sys-kernel/kait2en-t2thunderbolt" "sys-kernel/kait2en-t2smp" "sys-kernel/kait2en-t2mfi-fastcharge" "sys-kernel/kait2en-hid-t2magicmouse" "sys-kernel/kait2en-t2-precision-trackpad" "sys-kernel/kait2en-t2-trackpad-actuator" )
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/package-wrapper.sh"
