import 'package:native_prebuilt_hook/native_prebuilt_hook.dart';

/// Obtains libhrf_api in the mode chosen by the `build` user-define: the
/// pinned prebuilt (default), a verified Nix source build, or an unverified
/// Nix dev build. See the "Native library" section of the README.
Future<void> main(List<String> args) => runNativeBuildHook(
  args,
  const NativeLibrarySpec(
    packageName: 'frostdart',
    libraryBaseName: 'hrf_api',
    bindingsAssetName: 'frostdart_bindings_generated.dart',
    // Read by nix/build-apple.sh; the hook sets it, users do not.
    appleAnyXcodeVariable: 'FROSTDART_ANY_XCODE',
    // Rerun source and dev builds when what the Nix build reads changes.
    nativeSources: [
      'src/serai',
      'flake.nix',
      'flake.lock',
      'nix',
      'build-config.json',
    ],
  ),
);
