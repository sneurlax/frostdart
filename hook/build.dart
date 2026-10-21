import 'package:native_prebuilt_hook/native_prebuilt_hook.dart';

/// Obtains libhrf_api in the mode chosen by the `build` user-define or the
/// FROSTDART_BUILD environment variable: the pinned prebuilt (default), a
/// verified Nix source build, or an unverified Nix dev build. See the
/// "Native library" section of the README.
Future<void> main(List<String> args) => runNativeBuildHook(
  args,
  const NativeLibrarySpec(
    packageName: 'frostdart',
    libraryBaseName: 'hrf_api',
    bindingsAssetName: 'frostdart_bindings_generated.dart',
    modeEnvironmentVariable: 'FROSTDART_BUILD',
    anyXcodeEnvironmentVariable: 'FROSTDART_ANY_XCODE',
  ),
);
