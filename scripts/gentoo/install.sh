#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../fedora/lib.sh"

require_root
require_repo_root
require_gentoo
require_systemd
require_min_kernel 7 0

ask_touchbar() {
	local answer
	if ! has_touch_bar; then
		KAIT2EN_INSTALL_TOUCHBAR=0
		return
	fi
	case "${KAIT2EN_INSTALL_TOUCHBAR:-}" in
		1 | 0) return ;;
	esac
	if [[ ! -t 0 ]]; then
		KAIT2EN_INSTALL_TOUCHBAR=1
		return
	fi
	read -r -p "Install kait2en-touchbar? [Y/n] " answer || answer=
	case "${answer,,}" in
		n | no) KAIT2EN_INSTALL_TOUCHBAR=0 ;;
		*) KAIT2EN_INSTALL_TOUCHBAR=1 ;;
	esac
}
ask_touchbar
export KAIT2EN_INSTALL_TOUCHBAR

STEPS=(
	install-dependencies.sh
	install-apps.sh
	install-t2-services-common.sh
	install-t2-remote.sh
	install-touchid.sh
)

failed_steps=()
for step in "${STEPS[@]}"; do
	info "running $step"
	run_step "$step" bash "$SCRIPT_DIR/../gentoo/$step"
	if (( STEP_STATUS != 0 )); then
		failed_steps+=("$step")
	fi
done

if (( ${#failed_steps[@]} > 0 )); then
	warn "installation completed with errors in: ${failed_steps[*]}"
fi
info "All Kait2en Gentoo installation steps have been attempted"
info "reboot after reviewing the output"
