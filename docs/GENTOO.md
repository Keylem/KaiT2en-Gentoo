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

## From zero on a MacBook Pro T2

Use the [gentoo-repo beginner README](https://github.com/Keylem/gentoo-repo)
for Apple T2 Startup Security Utility, Gentoo systemd stage3 installation,
temporary USB tethering/Ethernet, overlay registration, firmware extraction,
kernel modules, apps and rollback. The overlay is the only supported Gentoo
package owner; never run the Fedora source installers on Gentoo.

## Pure Linux Wi-Fi (no macOS installed)

Unlike the old macOS-only firmware extraction process, this optional
workflow downloads an Apple Recovery image and extracts Broadcom firmware
entirely on Linux. It is based on
[kholia/OSX-KVM fetch-macOS-v2.py](https://github.com/kholia/OSX-KVM/blob/master/fetch-macOS-v2.py)
and the T2 Linux Wi-Fi/Bluetooth renaming tool.

1. Connect to the internet with Ethernet or USB phone tethering.
2. `sudo emerge -av app-misc/kait2en-wifi-tools`
3. `kait2en-wifi-setup prepare sonoma` as your **normal user**.
4. `sudo kait2en-wifi-setup stage "$HOME/.cache/kait2en-wifi/firmware.tar"`
5. `sudo emerge -av sys-firmware/kait2en-wifi-firmware`
6. Reboot and connect through NetworkManager.

Use `ventura` or `monterey` if the current recovery image lacks your
firmware. The required files depend on your exact Broadcom hardware.
The download is initiated only by the user; it can be hundreds of MB.
The proprietary firmware is **never redistributed** with KaiT2en and is
installed and removed through Portage. Temporary and staged user archive
copies remain in the local cache after unmerge for disaster recovery and can
be removed manually. Do not install `broadcom-wl` on T2 Macs; use the
kernel's `brcmfmac` driver.

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
