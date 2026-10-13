#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../fedora/lib.sh"

require_root
require_repo_root
require_gentoo
require_systemd

exec bash "$SCRIPT_DIR/../fedora/install-dsp.sh"
