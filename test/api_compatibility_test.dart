import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:test/test.dart';

void main() {
  test(
    'public wrapper result preserves the original field getter and setter',
    () {
      using((arena) {
        final result = arena<StartResharedRes>();
        final config = ffi.Pointer<MultisigConfig>.fromAddress(0x1234);
        result.ref.multisig_config = config;
        expect(result.ref.multisig_config, config);
        expect(result.ref.multisig_config$1, config);
      });
    },
  );
}
