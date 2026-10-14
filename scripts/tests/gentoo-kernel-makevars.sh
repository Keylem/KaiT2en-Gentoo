#!/usr/bin/env bash
# Ensure external kernel modules honour Gentoo's selected kernel tree.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
for rel in modules/t2bce_stack/Makefile t2-services/t2-ave/kernel/t2bce_ave/Makefile; do
    file="${root}/${rel}"
    grep -Fq 'KVERSION ?= $(if $(KERNELRELEASE),$(KERNELRELEASE),$(shell uname -r))' "${file}" ||
        { echo "Missing selected KERNELRELEASE support: ${rel}" >&2; exit 1; }
    grep -Fq 'KDIR ?= /lib/modules/$(KVERSION)/build' "${file}" ||
        { echo "Module build overrides KDIR: ${rel}" >&2; exit 1; }
done
echo "PASS: Kbuild honours Gentoo KDIR / KERNELRELEASE"
