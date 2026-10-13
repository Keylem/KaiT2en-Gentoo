#!/usr/bin/env bash
set -euo pipefail

APP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$APP_DIR/../../scripts/fedora/lib.sh"
require_root
install_kait2en_fonts
require_command make runuser

install_dependencies() {
	local distro
	distro=$(detect_distribution)
	case "$distro" in
		fedora)
			require_command dnf
			dnf install -y cargo gcc gtk4-devel libadwaita-devel
			;;
		gentoo)
			require_command emerge
			emerge --ask=n --quiet \
				dev-lang/rust \
				sys-devel/gcc \
				dev-build/make \
				gui-libs/gtk \
				gui-libs/libadwaita
			;;
		*)
			warn "automatic dependency installation is unsupported on this distribution; continuing"
			;;
	esac
	require_command cargo
}

install_dependencies

target_user=${SUDO_USER:-}
[[ -n "$target_user" && "$target_user" != root ]] ||
	fail "t2-power-explorer must be built for the user who invoked sudo"
build_group=$(id -gn "$target_user")
if [[ -d "$APP_DIR/target" ]]; then
	chown -R "$target_user:$build_group" "$APP_DIR/target"
fi
runuser -u "$target_user" -- make -C "$APP_DIR" build
make -C "$APP_DIR" install
clean_cargo_build "$APP_DIR" "$target_user"
info "t2-power-explorer installed"
