# frostdart

Dart bindings for the Serai FROST multisig implementation. Rust sources live in
`src/serai`; native assets build and bundle them automatically.

Requires Dart 3.13+ (or a Flutter SDK containing it), Rust installed with rustup,
and the platform's C build tools: Xcode for Apple, the Android NDK, a Linux C
compiler, or Visual Studio's C++ build tools on Windows. Put `rustup` on PATH.
The hook locates the pinned Rust 1.99.1 tools and installs the target as needed.

```sh
dart pub get --no-example
dart test
```

Consuming Flutter apps use normal `flutter run` / `flutter build` commands.
The example requires iOS 15+ or macOS 13+ for Apple builds.

Regenerate bindings with `dart run ffigen --config ffigen.yaml` (requires libclang).

## Native library

The hook obtains the Rust library in one of three modes, chosen with the
`build` user-define in the consuming app's `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    frostdart:
      build: prebuilt   # the default; or source, or dev
      # any_xcode: true # source builds of Apple targets skip the Xcode pin
      # developer_dir: /Applications/Xcode-27.0.app/Contents/Developer
```

- `prebuilt` downloads the library published for the pinned native release
  and verifies it against the hash recorded in `hook/prebuilt_hashes.json`.
  A mismatch is an error, never a fallback. Downloads are cached by hash.
- `source` builds the library with the Nix flake, the same build CI uses, and
  verifies it against the same hash. Apple targets require the pinned Xcode
  unless `any_xcode: true`, in which case the hash check still applies.
- `dev` builds with the Nix flake but skips the Xcode pin and the hash check,
  for working on the Rust code.

`developer_dir` selects the Xcode for Apple builds when `xcode-select`
points elsewhere (for example at the Command Line Tools); relative paths
resolve against the pubspec that sets it.

The settings are user-defines, not environment variables, because the hooks
runner that `dart test`, `dart run` and `flutter build` use starts hooks with
a filtered environment: only PATH, HOME, the temp and proxy variables, the
Android NDK variables, a few Windows ones, and names starting with `CARGO_`,
`CCACHE_`, `DOTNET_`, `NIX_`, `NUGET_`, `RUSTUP_` or `CONAN_` get through (see
`includeHookEnvironmentVariable` in
[hooks_runner's build_runner.dart](https://github.com/dart-lang/native/blob/main/pkgs/hooks_runner/lib/src/build_runner/build_runner.dart)).
Setting `FROSTDART_BUILD` or `DEVELOPER_DIR` in the shell has no effect on
the hook. `NIX_CONFIG` does get through, and the hook adds the line that
enables flakes to whatever it contains. The filtered environment also has no
`SSH_AUTH_SOCK`: if the flake fetches an input over `git+ssh://` (such as
the native-build-kit flake from the Cypher Stack Gitea), Nix inside the hook
cannot use an SSH agent, so the key must be usable from `~/.ssh` without one.

Only dynamic libraries are provided, built for macOS 12, iOS 15, Android API
24, and glibc 2.28 at minimum. The floors, the canonical path prefixes, and
the toolchain versions live in `build-config.json`.

`hook/build.dart` is a thin call into the `native_prebuilt_hook` package from
[native-build-kit](https://git.cypherstack.com/sneurlax/native-build-kit),
which implements the three modes for every plugin built with the kit. Source
and dev builds read a git checkout (a clone or a worktree) as a git flake, so
only tracked files are inputs, and a package in the pub cache as a plain
path. They need Nix, so on Windows only the prebuilt mode works outside WSL2.

### Native releases

Pushing a `native-<version>` tag runs `.github/workflows/native-release.yml`:
it builds every sandboxed target, rebuilds each from scratch, publishes the
dynamic libraries and a SHA256SUMS as a GitHub release, and commits their
hashes to `hook/prebuilt_hashes.json` on the branch the tag was cut from. The
hashes shipped in a package version therefore pin the exact bytes consumers
receive, and anyone can rebuild one platform with Nix and compare:
`dart tool/verify_release.dart linux` (or android, windows, macos, ios, or a
single target triple), on any host with Nix, which on Windows means WSL2. The
Apple platforms need the pinned Xcode; if `xcode-select` points at the Command
Line Tools, set `DEVELOPER_DIR` to the Xcode bundle's `Contents/Developer`. The Apple
libraries come from the macOS job, which builds them with the pinned Xcode;
the release is only published when both hosts succeed and agree.

### Reference builds with Nix

`flake.nix` builds every non-Apple target in a sandbox through
[native-build-kit](https://git.cypherstack.com/sneurlax/native-build-kit)'s
`mkCargoLibrary`, whose nixpkgs, Rust and zig pins it follows. The toolchains
are pinned by hash: the official Rust and zig releases, lld from nixpkgs for the Windows
link, the Windows SDK fetched by xwin from a pinned manifest, and the Android
NDK. The versions live in `build-config.json` under `toolchains`.

Two details make the output independent of the build host. Cargo mixes
rustc's host triple into the metadata hash of build scripts and proc macros,
and from there into the symbol hash of nearly every crate, so the flake runs
rustc through a wrapper that reports a fixed host for cargo's `rustc -vV`
query. And C code is compiled by zig's bundled clang on every target, because
nixpkgs' separately built clang emitted different code per host platform.

```sh
nix build .#x86_64-unknown-linux-gnu    # one target, output in result/lib
nix build .#all                         # every target this host can build
cat result/SHA256SUMS
```

Apple targets need the pinned Xcode on the host, so they are built by a script
inside the flake's Apple shell, which checks the Xcode version first:

```sh
nix develop .#apple --command nix/build-apple.sh out
```

Linux and macOS hosts build the Linux, Android, and Windows targets; macOS
also builds the Apple ones. Android builds link the Linux NDK package's
`crtbegin` objects on every host, because Google compiles those with each
host package's own clang and the darwin and Linux copies differ. On Windows, run the same commands inside WSL2
with the checkout on the Linux filesystem. The first build of the Windows
target reports the hash of the xwin SDK output; paste it into
`toolchains.xwin.splatHash`.

### Continuous verification

`.github/workflows/reproducible.yml` builds the sandboxed targets with Nix on
a Linux x86_64 runner, a Linux aarch64 runner, a macOS runner, and inside WSL2
on a Windows runner, rebuilds each from scratch with `nix build --rebuild`,
and builds the Apple targets on the macOS runner with the pinned Xcode. A final
job runs `tool/compare_sums.sh` over every host's SHA256SUMS and fails if a
target built on more than one host differs. The test workflow builds through
the hook in dev mode on Linux and macOS, and runs the Dart tests on Windows
against the prebuilt library once a native release exists.
