#!/usr/bin/env bash
# Ensure old Gentoo entrypoints cannot silently write Fedora-managed files.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
for wrapper in "${root}"/scripts/gentoo/install-*.sh; do
    bash -n "${wrapper}"
    bash "${wrapper}" --help >/dev/null
    grep -q 'package-wrapper.sh' "${wrapper}" ||
        [[ ${wrapper} == */install.sh ]] || {
        echo "Non-Portage Gentoo installer: ${wrapper}" >&2
        exit 1
    }
    if [[ ${wrapper} != */install.sh ]] &&
        grep -Eq '(fedora/|dkms|make install|/usr/local/)' <(grep -v '^#' "${wrapper}"); then
        echo "Found destructive legacy code in ${wrapper}" >&2
        exit 1
    fi
done
bash -n "${root}/scripts/gentoo/package-wrapper.sh"
echo "PASS: Gentoo installer entrypoints delegate to Portage"
