#!/usr/bin/env bash
# Gentoo installs are owned by Portage, not by the Fedora-style source installer.
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: sudo ./scripts/gentoo/install.sh [--pretend|--help]

Install the KaiT2en metapackage from the 'keylem' Gentoo overlay.
Configure /etc/portage/repos.conf/keylem.conf and accept live ebuilds
before running this script. Services are not enabled automatically.
EOF
}

mode=install
case "${1:-}" in
    "") ;;
    --pretend) mode=pretend ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
if (( $# > 1 )); then
    usage >&2
    exit 2
fi

[[ $(id -u) -eq 0 ]] || { echo "Run with sudo/root" >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo "Missing /etc/os-release" >&2; exit 1; }
# shellcheck source=/dev/null
source /etc/os-release
[[ "${ID:-}" == gentoo || " ${ID_LIKE:-} " == *" gentoo "* ]] ||
    { echo "This installer supports Gentoo only" >&2; exit 1; }
[[ -d /run/systemd/system ]] ||
    { echo "A running systemd Gentoo profile is required" >&2; exit 1; }
for cmd in emerge portageq; do
    command -v "$cmd" >/dev/null 2>&1 ||
        { echo "Missing required command: $cmd" >&2; exit 1; }
done

if ! overlay_path=$(portageq get_repo_path / keylem 2>/dev/null) ||
   [[ ! -f "$overlay_path/profiles/repo_name" ]]; then
    cat >&2 <<'EOF'
The 'keylem' Gentoo overlay is not configured.
See https://github.com/Keylem/gentoo-repo for repos.conf setup.
Run 'emaint sync -r keylem' and configure package.accept_keywords
for the selected live (9999) ebuilds before installing.
EOF
    exit 1
fi

echo "Using Portage overlay: $overlay_path"
echo "Package: app-misc/kait2en"
echo "Nothing will be installed outside Portage; services must be enabled manually."
if [[ "$mode" == pretend ]]; then
    exec emerge --pretend --verbose app-misc/kait2en
fi
exec emerge --ask --verbose app-misc/kait2en
