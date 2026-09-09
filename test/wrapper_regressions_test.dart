import 'dart:ffi';

import 'package:test/test.dart';
import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:frostdart/util.dart';

import 'fixtures.dart';

void main() {
  test('Unicode config names and participants round trip', () {
    final config = newMultisigConfig(
      name: 'éé雪🔑',
      threshold: 2,
      participants: ['Álice', 'ボブ'],
    );
    expect(multisigName(multisigConfig: config), 'éé雪🔑');
    expect(multisigParticipant(index: 0, multisigConfig: config), 'Álice');
    final start = startKeyGen(
      multisigConfig: config,
      myName: 'ボブ',
      language: Language.english,
    );
    expect(
      multisigMyName(multisigConfigWithNamePointer: start.ref.config),
      'ボブ',
    );
  });
  test('borrowed participant name survives repeated reads', () {
    final config = newMultisigConfig(
      name: 'wallet',
      threshold: 2,
      participants: ['alice', 'bob'],
    );
    final start = startKeyGen(
      multisigConfig: config,
      myName: 'alice',
      language: Language.english,
    );
    for (var i = 0; i < 5; i++) {
      expect(
        multisigMyName(multisigConfigWithNamePointer: start.ref.config),
        'alice',
      );
    }
  });
  test('signInput returns the script rather than txid bytes', () {
    final keys = deserializeKeys(keys: vectorKeys);
    final config = signingConfig(keys);
    final output = signInput(
      thresholdKeysWrapperPointer: keys,
      signConfig: config,
      network: Network.Regtest,
      index: 0,
    );
    expect(output.hash, inputHash);
    expect(output.scriptPubKey, inputScript);
  });
  test('borrowed payment and change survive repeated reads', () {
    final keys = deserializeKeys(keys: vectorKeys);
    final config = decodeSignConfig(
      thresholdKeysWrapperPointer: keys,
      network: Network.Regtest,
      encodedSignConfig: signingConfig(keys),
    );
    for (var i = 0; i < 5; i++) {
      expect(
        signPaymentAddress(signConfigPointer: config, index: 0),
        destination,
      );
      expect(signChange(signConfigPointer: config), destination);
    }
  });
  test('borrowed resharing participant survives repeated reads', () {
    final config = decodeResharerConfig(
      resharerConfig: newResharerConfig(
        newThreshold: 2,
        resharers: [0, 1],
        newParticipants: ['alice', 'bob'],
      ),
    );
    for (var i = 0; i < 5; i++) {
      expect(
        resharerNewParticipant(resharerConfigPointer: config, index: 0),
        'alice',
      );
    }
  });
}
