#!/usr/bin/env bash
# Compatibility entrypoints for Gentoo; do not call Fedora/DKMS installers.
set -euo pipefail

case ${1:-} in
    --pretend) mode=pretend ;;
    --help|-h)
        echo "Usage: sudo ./scripts/gentoo/$(basename -- "${BASH_SOURCE[1]}") [--pretend]"
        exit 0 ;;
    "") mode=install ;;
    *) echo "Only --pretend or --help is supported" >&2; exit 2 ;;
esac
(( $# < 2 )) || { echo "Unexpected arguments" >&2; exit 2; }

if (( EUID != 0 )); then
    echo "Run via sudo/root. All installed files must be Portage-owned." >&2
    exit 1
fi
[[ -r /etc/os-release ]] || { echo "Missing /etc/os-release" >&2; exit 1; }
# shellcheck source=/dev/null
source /etc/os-release
[[ ${ID:-} == gentoo || " ${ID_LIKE:-} " == *" gentoo "* ]] ||
    { echo "This entrypoint only supports Gentoo" >&2; exit 1; }
[[ -d /run/systemd/system ]] || {
    echo "A running systemd Gentoo installation is required" >&2
    exit 1
}
command -v emerge >/dev/null || { echo "Portage missing" >&2; exit 1; }
command -v portageq >/dev/null || { echo "portageq missing" >&2; exit 1; }
if ! root=$(portageq get_repo_path / keylem 2>/dev/null) ||
   [[ ! -f ${root}/profiles/repo_name ]]; then
    echo "Configure the keylem Portage overlay before running this entrypoint" >&2
    exit 1
fi
if [[ ${mode} == pretend ]]; then
    exec emerge --pretend --verbose --oneshot "${PACKAGES[@]}"
fi
exec emerge --ask --verbose --oneshot "${PACKAGES[@]}"
