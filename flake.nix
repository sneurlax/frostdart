{
  description = "Reproducible reference builds of frostdart's Rust library (hrf-api)";

  inputs = {
    # The build itself lives in the kit; it also pins nixpkgs and the Rust
    # and zig overlays, and this flake follows those pins.
    kit.url = "git+ssh://git@git.cypherstack.com:222/sneurlax/native-build-kit.git?ref=feat/native-build-kit";
    nixpkgs.follows = "kit/nixpkgs";
    rust-overlay.follows = "kit/rust-overlay";
    zig-overlay.follows = "kit/zig-overlay";
  };

  outputs = { self, kit, ... }:
    kit.lib.mkCargoLibraryOutputs {
      settings = builtins.fromJSON (builtins.readFile ./build-config.json);
      crate = "hrf-api";
      src = ./src/serai;
      srcName = "serai";
      libraryBaseName = "hrf_api";
      appleInstallName = "@rpath/libhrf_api.dylib";
    };
}
