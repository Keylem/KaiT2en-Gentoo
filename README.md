<p align="center">
  <img src="assets/kait2en-fedora.jpeg" alt="KAIT2EN logo" width="720">
</p>

# KAIT2EN

KAIT2EN brings cutting edge T2 Mac support to Linux systems using DKMS modules
and systemd-integrated services.

[Docs](https://kait2en.org/documentation.html) |
[Blog](https://kait2en.org/blog.html) |
[Community](#community) |
[Contributing](#contributing)

## Install

Follow the [installation guide](https://kait2en.org/documentation.html#overview).

Some Rust apps are built during installation, and their Cargo target folders
are cleaned by default. Set `KAIT2EN_CARGO_CLEAN=0` to keep them.

### Gentoo (systemd)

**Use the [keylem Portage overlay](https://github.com/Keylem/gentoo-repo)** to install
KaiT2en on Gentoo. The Fedora-oriented source installation scripts are not
the Gentoo packaging interface. Portage manages installed files, dependencies,
kernel modules and upgrades. No services are enabled automatically.

Configure `/etc/portage/repos.conf/keylem.conf`:

```ini
[keylem]
location = /var/db/repos/keylem
sync-type = git
sync-uri = https://github.com/Keylem/gentoo-repo.git
auto-sync = yes
```

Then run `sudo emaint sync -r keylem`. Live packages use version `9999` and
need explicit keyword acceptance for the selected packages; see the overlay
README for examples and kernel/hardware restrictions.

```bash
sudo ./scripts/gentoo/install.sh --pretend
sudo ./scripts/gentoo/install.sh
```

**Wi-Fi on a pure Linux MacBook Pro (no macOS partition):**
Once Gentoo is running with a temporary USB tether or Ethernet connection,
install `app-misc/kait2en-wifi-tools` from the overlay, then run
`kait2en-wifi-setup prepare sonoma` **as your normal user**. The tool
retrieves an Apple recovery image using the approach in
[kholia/OSX-KVM](https://github.com/kholia/OSX-KVM/blob/master/fetch-macOS-v2.py),
renames the Broadcom firmware using the T2 Linux tool, and creates a local
archive. Run `sudo kait2en-wifi-setup stage
"$HOME/.cache/kait2en-wifi/firmware.tar"` followed by
`after accepting the package-specific
`all-rights-reserved` license in `/etc/portage/package.license/`, run
`sudo emerge -av sys-firmware/kait2en-wifi-firmware`` and reboot.
No Apple firmware is included in this source repo or automatically downloaded
by Portage. This process needs temporary wired/USB Internet access.
The overlay's [beginner README](https://github.com/Keylem/gentoo-repo)
starts from T2 boot-security setup and explains every step.

The entrypoint requires a running systemd Gentoo system and an already configured
overlay. It invokes Portage only; it does not build or install files via
`make install`, DKMS or direct systemd enablement. Confirm proposed
USE flags and dependencies before proceeding. Keep a fallback boot entry for
kernel-related changes. System testing on the target T2 Mac is still required.

## Community

Join the KAIT2EN community on [Discord](https://discord.gg/AGfjRk4ydj) or on
[Matrix](https://matrix.to/#/%23kait2en:matrix.org).

## Contributing

Contributions are welcome, especially when they move KAIT2EN fixes closer to
clean upstream Linux support.

Please keep changes and PR descriptions focused.
**We will reject PRs and Issues when we notice we are talking to AI!**
At least talk to us in person.
We are not interested in workarounds.
We are not interested in major AI refactories.
There is a distinct difference between making broken things work and fixing things.

## License

KAIT2EN-owned scripts, howto documents, project text and helper code are MIT
licensed.

Kernel modules, apps and third-party tools may include code with different
origins. Those components keep their own licenses in their directories.

The kernel modules are GPL-2.0; everything else KAIT2EN writes, apps, protocols,
audio DSP profiles and scripts, is GPL-3.0-or-later. The full breakdown is in
[LICENSING.md](LICENSING.md).

The code licenses do not grant the KAIT2EN name or logo. Their use, and what
the project stands for, are described in [TRADEMARK.md](TRADEMARK.md) and
[VALUES.md](VALUES.md).

The individual source `scripts/gentoo/install-*.sh` entrypoints are now only
Portage compatibility wrappers; no legacy Fedora, DKMS, or `/usr/local`
installations are performed by them. For **all applications**, systemd setup,
kernel sources and the Gentoo + OpenZFS kernel option see
[docs/GENTOO.md](docs/GENTOO.md) and the overlay's application guide.
The source GUI kernel builder still targets Fedora; on Gentoo install
`app-misc/t2-kernel-builder` for the native Portage CLI instead.
