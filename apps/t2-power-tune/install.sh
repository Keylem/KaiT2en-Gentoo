#!/usr/bin/env bash
# On Gentoo, only the overlay may install these files.
if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ ${ID:-} == gentoo || " ${ID_LIKE:-} " == *" gentoo "* ]]; then
        printf '%s\n' 'Gentoo installation must use the keylem Portage overlay.' >&2
        printf '%s\n' 'See https://github.com/Keylem/gentoo-repo and docs/GENTOO.md.' >&2
        exit 2
    fi
fi

set -euo pipefail
APP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$APP_DIR/../../scripts/fedora/lib.sh"
require_root
install_kait2en_fonts
require_command install gtk-update-icon-cache update-desktop-database

install_dependencies() {
	local distro
	distro=$(detect_distribution)
	case "$distro" in
		fedora)
			require_command dnf
			dnf install -y gtk4 libadwaita pciutils polkit python3-gobject
			;;
		gentoo)
			require_command emerge
			emerge --ask=n --quiet \
				gui-libs/gtk \
				gui-libs/libadwaita \
				sys-apps/pciutils \
				sys-auth/polkit \
				dev-python/pygobject \
				x11-misc/desktop-file-utils
			;;
		*)
			warn "automatic dependency installation is unsupported on this distribution; continuing"
			;;
	esac
}
install_dependencies
install -d -m 0755 /usr/local/bin /usr/local/libexec /usr/local/share/applications \
    /usr/local/share/icons/hicolor/scalable/apps /usr/share/polkit-1/actions
install -m 0755 "$APP_DIR/t2-power-tune.py" /usr/local/bin/t2-power-tune
install -m 0755 "$APP_DIR/t2-power-tune-helper" /usr/local/libexec/t2-power-tune-helper
install -m 0755 "$APP_DIR/t2-power-tune-status" /usr/local/libexec/t2-power-tune-status
rm -f /usr/local/libexec/t2-power-tune-cstates
install -m 0644 "$APP_DIR/org.t2powertune.policy" /usr/share/polkit-1/actions/
install -m 0644 "$APP_DIR/org.t2powertune.gtk.desktop" /usr/local/share/applications/
install -m 0644 "$APP_DIR/org.t2powertune.gtk.svg" /usr/local/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache --force --ignore-theme-index /usr/local/share/icons/hicolor
update-desktop-database /usr/local/share/applications
info "t2-power-tune installed"
