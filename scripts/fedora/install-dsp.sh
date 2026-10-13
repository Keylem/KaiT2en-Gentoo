#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

require_root
require_repo_root
require_systemd
require_command id make python3 runuser

clear_user_audio_sink_default() {
    local user=${SUDO_USER:-} uid runtime

    if [[ -z "$user" || "$user" == root ]]; then
        warn "cannot determine non-root user; run 'wpctl clear-default 0' after login"
        return 0
    fi

    uid="$(id -u "$user")"
    runtime="/run/user/$uid"
    if [[ ! -d "$runtime" ]]; then
        warn "user runtime $runtime is not active; run 'wpctl clear-default 0' after login"
        return 0
    fi

    if ! runuser -u "$user" -- env XDG_RUNTIME_DIR="$runtime" \
        wpctl clear-default 0; then
        warn "could not clear the configured audio sink; run 'wpctl clear-default 0' as $user"
    fi
}

install_dsp_dependencies() {
	local distro
	distro=$(detect_distribution)
	case "$distro" in
		fedora)
			require_command dnf
			dnf install -y \
				pipewire pipewire-pulseaudio 'wireplumber >= 0.5.8' \
				pipewire-module-filter-chain-lv2 lv2-bankstown lsp-plugins-lv2
			;;
		gentoo)
			require_command emerge
			emerge --ask=n --quiet \
				media-video/pipewire \
				media-video/wireplumber \
				media-libs/lv2 \
				media-plugins/lsp-plugins
			;;
		*)
			warn "automatic DSP dependency installation is unsupported on this distribution"
			return 1
			;;
	esac
}

# Install all profiles, exactly as in the standalone package. udev and
# WirePlumber choose the model at runtime, not on the installation/build host.
run_step "install DSP dependencies" install_dsp_dependencies

if (( STEP_STATUS == 0 )); then
    run_step "install DSP profiles and integration" make -C "$REPO_ROOT/dsp" install PREFIX=/usr
    if (( STEP_STATUS == 0 )); then
        run_step "migrate legacy DSP configuration" bash /usr/libexec/t2-dsp/package-actions configure
        if (( STEP_STATUS == 0 )); then
            run_step "enable automatic audio output selection" clear_user_audio_sink_default
        fi
    else
        warn "DSP files were not fully installed. Legacy configuration was left in place"
    fi
else
    warn "DSP dependencies could not be installed. Existing DSP files and configuration were left in place"
fi

info "DSP installation steps finished. Reboot to activate. User audio services were not restarted"
