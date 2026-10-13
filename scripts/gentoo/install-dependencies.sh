#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../fedora/lib.sh"

require_root
require_repo_root
require_gentoo
require_systemd
require_command emerge

KVER="$(kernel_release)"

if [[ -f "/lib/modules/$KVER/build/Makefile" ]]; then
	info "using kernel build tree /lib/modules/$KVER/build"
else
	warn "kernel build tree is unavailable at /lib/modules/$KVER/build; DKMS builds may fail"
fi

info "installing Gentoo build and runtime dependencies for $KVER"
packages=(
	app-admin/sudo
	sys-kernel/dkms
	sys-devel/gcc
	dev-build/make
	dev-lang/rust
	dev-util/pkgconf
	dev-python/pygobject
	x11-libs/gtk+
	gui-libs/libadwaita
	dev-libs/libinput
	dev-libs/libplist
	sys-apps/systemd
	sys-apps/polkit
	sys-auth/fprintd
	sys-auth/libfprint
	media-libs/alsa-ucm-conf
	media-fonts/jetbrains-mono
)

failed_packages=()
for package in "${packages[@]}"; do
	if ! emerge --ask=n --quiet "$package"; then
		warn "failed to install dependency $package; continuing"
		failed_packages+=("$package")
	fi
done

if (( ${#failed_packages[@]} > 0 )); then
	warn "dependency installation completed with errors in: ${failed_packages[*]}"
fi

info "dependencies installed"
