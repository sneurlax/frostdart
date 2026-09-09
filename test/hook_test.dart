import 'dart:io';

import 'package:test/test.dart';

import '../hook/build.dart' as hook;

void main() {
  test(
    'successful tool progress does not become Flutter error output',
    () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'test/fixtures/hook_process.dart',
        '0',
      ]);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('tool stdout'));
      expect(result.stdout, contains('tool stderr'));
      expect(result.stderr, isEmpty);
    },
  );
  test('failed tools retain diagnostics and failure status', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'test/fixtures/hook_process.dart',
      '7',
    ]);
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('tool stderr'));
    expect(result.stderr, contains('Native build failed'));
  });
  test('missing rustup has an actionable prerequisite error', () async {
    final missing = Directory.systemTemp.createTempSync('frostdart-no-rustup-');
    try {
      await expectLater(
        hook.run('rustup', ['--version'], missing.uri, {'PATH': missing.path}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Install rustup and put it on PATH'),
          ),
        ),
      );
    } finally {
      missing.deleteSync();
    }
  });
}
