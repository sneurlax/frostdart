#!/usr/bin/env bash
# Builds the Apple targets through the kit's build-apple.sh, which the Apple
# shell provides as $KIT_BUILD_APPLE. Run from inside the flake's Apple shell:
#
#   nix develop .#apple --command nix/build-apple.sh <output-dir> [target...]
#
# Outputs land in <output-dir>/<target>/ with a SHA256SUMS.apple beside them.
# FROSTDART_ANY_XCODE=1 builds with whatever xcode-select points at.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd -P)
export KIT_FLAKE_DIR=$root
export KIT_CONFIG=$root/build-config.json
export KIT_SOURCE_DIR=$root/src/serai
export KIT_MANIFEST_PATH=hrf/Cargo.toml
export KIT_CRATE=hrf-api
export KIT_LIBRARY_BASE_NAME=hrf_api
export KIT_APPLE_INSTALL_NAME=@rpath/libhrf_api.dylib
export KIT_LOG_NAME=frostdart
if [ "${FROSTDART_ANY_XCODE:-}" = 1 ]; then export KIT_ANY_XCODE=1; fi

exec bash "${KIT_BUILD_APPLE:?run inside nix develop .#apple}" "$@"
