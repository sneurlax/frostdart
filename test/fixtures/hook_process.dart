import 'dart:io';

import '../../hook/build.dart' as hook;

Future<void> main(List<String> args) async {
  if (args.first == 'child') {
    stdout.writeln('tool stdout');
    stderr.writeln('tool stderr');
    exitCode = int.parse(args[1]);
    return;
  }
  await hook.run(
    Platform.resolvedExecutable,
    [Platform.script.toFilePath(), 'child', args.first],
    Directory.current.uri,
    {},
  );
}
