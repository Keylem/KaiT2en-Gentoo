#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../fedora/lib.sh"
require_root
require_repo_root
require_gentoo
require_systemd

COMPONENT="$REPO_ROOT/t2-services/t2-touchid"
CONFIG_DST=/etc/kait2en/t2-touchid.conf

build_touchid() {
	local target_user="${SUDO_USER:-}"
	[[ -n "$target_user" && "$target_user" != root ]] || fail "t2-touchid must be built by the invoking user"
	sudo -H -u "$target_user" make -C "$COMPONENT" build
}

install_policy() {
	if command -v checkmodule >/dev/null 2>&1 &&
		command -v semodule_package >/dev/null 2>&1; then
		make -C "$COMPONENT/integration/selinux"
		install -D -m 0644 "$COMPONENT/integration/selinux/kait2en-t2-touchid.pp" /usr/share/selinux/packages/kait2en-t2-touchid.pp
		python3 "$REPO_ROOT/packaging/lifecycle/kait2en-lifecycle.py" t2-touchid install-policy
	else
		warn "SELinux policy toolchain not found; skipping Touch ID SELinux policy installation"
	fi
}

install_touchid() {
	local new_config=0
	[[ -e "$CONFIG_DST" ]] || new_config=1
	make -C "$COMPONENT" install SYSTEMD_UNIT_DIR=/etc/systemd/system DATADIR=/usr/share
	if (( new_config )) && [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
		sed -i "s/^T2_TOUCHID_BIND_USER=.*/T2_TOUCHID_BIND_USER=$SUDO_USER/" "$CONFIG_DST"
	fi
	python3 "$REPO_ROOT/packaging/lifecycle/kait2en-lifecycle.py" t2-touchid record-source
}

activate_touchid() {
	systemctl daemon-reload
	if [[ -d /run/t2-touchid ]] && command -v restorecon >/dev/null 2>&1; then
		restorecon -R /run/t2-touchid
	fi
	systemctl enable kait2en-t2-touchid.service
	systemctl restart kait2en-t2-touchid.service
}

reload_dbus() {
	if systemctl is-active --quiet dbus-broker.service; then
		systemctl reload dbus-broker.service
	else
		systemctl reload dbus.service
	fi
}

run_step "build t2-touchid" build_touchid
build_status=$STEP_STATUS
run_step "install Touch ID SELinux policy" install_policy
if (( build_status == 0 )); then
	run_step "install t2-touchid files" install_touchid
	if (( STEP_STATUS == 0 )); then
		run_step "reload D-Bus policy" reload_dbus
		run_step "activate t2-touchid" activate_touchid
		if (( STEP_STATUS == 0 )); then
			run_step "restart active fprintd" systemctl try-restart fprintd.service
			run_step "enable fingerprint PAM feature with ownership receipt" python3 "$REPO_ROOT/packaging/lifecycle/kait2en-lifecycle.py" t2-touchid enable-pam
		fi
	fi
else
	record_error "Touch ID installation skipped because its build failed; existing installation retained"
fi

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
	clean_cargo_build "$COMPONENT" "$SUDO_USER"
fi
