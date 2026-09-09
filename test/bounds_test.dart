import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';

import 'fixtures.dart';

void main() {
  test('out-of-range config and payment indexes throw in Dart', () {
    final multisig = newMultisigConfig(
      name: 'wallet',
      threshold: 2,
      participants: ['alice', 'bob'],
    );
    final keys = deserializeKeys(keys: vectorKeys);
    final encodedSign = signingConfig(keys);
    final sign = decodeSignConfig(
      thresholdKeysWrapperPointer: keys,
      network: Network.Regtest,
      encodedSignConfig: encodedSign,
    );
    final resharer = decodeResharerConfig(
      resharerConfig: newResharerConfig(
        newThreshold: 2,
        resharers: [0, 1],
        newParticipants: ['alice', 'bob'],
      ),
    );
    for (final index in [-1, 2, 65536]) {
      expect(
        () => multisigParticipant(index: index, multisigConfig: multisig),
        throwsRangeError,
      );
      expect(
        () => signInput(
          thresholdKeysWrapperPointer: keys,
          signConfig: encodedSign,
          network: Network.Regtest,
          index: index,
        ),
        throwsRangeError,
      );
      expect(
        () => signPaymentAddress(signConfigPointer: sign, index: index),
        throwsRangeError,
      );
      expect(
        () => signPaymentAmount(signConfigPointer: sign, index: index),
        throwsRangeError,
      );
      expect(
        () => resharerResharer(resharerConfigPointer: resharer, index: index),
        throwsRangeError,
      );
      expect(
        () => resharerNewParticipant(
          resharerConfigPointer: resharer,
          index: index,
        ),
        throwsRangeError,
      );
    }
  });
  test('invalid network values never reach the Rust enum ABI', () {
    final keys = deserializeKeys(keys: vectorKeys);
    for (final network in [-1, 3, 4294967296]) {
      expect(
        () => addressForKeys(
          network: network,
          keys: keys,
          addressDerivationData: derivation,
          secure: true,
        ),
        throwsRangeError,
      );
      expect(
        () => decodeSignConfig(
          thresholdKeysWrapperPointer: keys,
          network: network,
          encodedSignConfig: '',
        ),
        throwsRangeError,
      );
    }
  });
  test('fixed-size values are not silently padded or truncated', () {
    final keys = deserializeKeys(keys: vectorKeys);
    for (final length in [0, 31, 33]) {
      expect(
        () => signingConfig(keys, hash: Uint8List(length)),
        throwsArgumentError,
      );
    }
    expect(
      () => newMultisigConfig(
        name: 'wallet',
        threshold: 65537,
        participants: ['alice'],
      ),
      throwsRangeError,
    );
    expect(
      () => newResharerConfig(
        newThreshold: 1,
        resharers: [65536],
        newParticipants: ['alice'],
      ),
      throwsRangeError,
    );
  });
}
