import 'dart:ffi';

import 'package:test/test.dart';
import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart' as native;
import 'package:frostdart/util.dart';

import 'fixtures.dart';

void main() {
  test('script pubkey ABI returns CResult and a P2TR script', () {
    final keys = deserializeKeys(keys: vectorKeys);
    final result = native.script_pubkey_for_keys(keys, 0, 0, false, true);
    expect(result.err, SUCCESS);
    try {
      final script = result.value.ref.toDartString();
      expect(script, startsWith('5120'));
      expect(script.length, 68);
    } finally {
      native.free_owned_string(result.value.ref);
    }
  });
  test('repeated address derivation succeeds', () {
    final keys = deserializeKeys(keys: vectorKeys);
    for (var i = 0; i < 100; i++) {
      expect(
        addressForKeys(
          network: native.Network.Regtest,
          keys: keys,
          addressDerivationData: derivation,
          secure: true,
        ),
        startsWith('bcrt1p'),
      );
    }
  });
  test('derivation error is named', () {
    expect(getErrorName(72), 'INVALID_DERIVATION_ERROR');
  });
}
