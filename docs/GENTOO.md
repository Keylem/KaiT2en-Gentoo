# Gentoo Linux: supported Portage installation

The maintained Gentoo-facing package integration lives in
[Keylem/gentoo-repo](https://github.com/Keylem/gentoo-repo).
Use its [installation and app guide](https://github.com/Keylem/gentoo-repo/blob/main/docs/INSTALL-AND-USE.md).
That guide explains *every app*, driver, systemd unit, daemon, group, and
the two kernel workflows. It is updated independently from this source tree.

Do **not** use the Fedora `make install`, `apps/t2-kernel-builder/engine/build.sh`,
RPM, DKMS or standalone app `install.sh` recipes on Gentoo. The Fedora
kernel builder and graphical frontend are **not** a Gentoo kernel builder.
The Gentoo CLI `t2-kernel-builder` is distributed by the overlay.

## Setup

- Install amd64 Gentoo with a running systemd profile.
- Add the `keylem` Portage overlay and accept the chosen live ebuild atoms.
- `sudo emerge -av app-misc/kait2en` installs the default application set.
- Install additional atoms individually where needed. For example,
  `sudo emerge -av app-misc/t2-force-click` installs Force Click plus its
  declared kernel module dependencies.
- The compatibility shims `scripts/gentoo/install-*.sh` now do *only*
  Portage `emerge` calls, with no direct file deletion, DKMS registration,
  systemd enablement, or Fedora package installation.
- Each systemd unit is installed but disabled by default. Enable only services
  appropriate to your Mac model.

## Kernel + OpenZFS

Two independent overlay metapackages are provided:

1. `sys-kernel/kait2en-sources` installs Gentoo-patched sources
   (`sys-kernel/gentoo-sources`) and the T2 patch validation toolkit.
2. `sys-kernel/kait2en-kernel-openzfs` installs a *source-built* Gentoo
   distribution kernel (`sys-kernel/gentoo-kernel`) with `sys-fs/zfs`
   configured for a matching, **external** OpenZFS kernel module.

They do not force unverified experimental T2 kernel patches into an existing
bootable kernel. To opt in, check the entire ordered patch series with
`kait2en-kernel-preflight` against the exact Linux tree, review it, and
place compatible patches under that kernel package's
`/etc/portage/patches/sys-kernel/<package>/` path before emerge.
A clean patch application does not certify OpenZFS compatibility.

For root on ZFS, rebuild the matching ZFS modules and initramfs, validate
the bootloader entry and test the real machine while retaining a known-good
kernel and pool backup. OpenZFS is generally built as a separate module;
the phrase "build kernel with ZFS" does not imply linking its CDDL code into
the mainline kernel image.

## Updates and removal

Always use Portage to rebuild or unmerge these packages. Do not combine the
Gentoo overlay with pre-existing `/usr/local` installs of the same daemons.
The source's old Fedora installers do not manage Portage-owned files.
Per-user configs and saved application state are intentionally preserved on
unmerge and may be removed manually after backing them up.

## Status

The overlay has automated dependency, syntax and limited lifecycle checks.
Actual builds of every live Rust application, every external kernel driver,
and patched kernel with a matching OpenZFS module require testing against
the specific Gentoo kernel/version/hardware. No 100% compatibility guarantee
is made for arbitrary kernel releases or Mac models.
