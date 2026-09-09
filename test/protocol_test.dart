import 'dart:ffi';
import 'dart:typed_data';

import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:frostdart/util.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('fresh Unicode 2-of-2 keygen, signing, resharing and signing again', () {
    const names = ['Álice', 'ボブ'];
    const languages = [Language.english, Language.japanese];
    final encoded = newMultisigConfig(
      name: '共同財布🔑',
      threshold: 2,
      participants: names,
    );
    final starts = List.generate(
      2,
      (i) => startKeyGen(
        multisigConfig: encoded,
        myName: names[i],
        language: languages[i],
      ),
    );
    for (var i = 0; i < 2; i++) {
      expect(
        multisigMyName(multisigConfigWithNamePointer: starts[i].ref.config),
        names[i],
      );
      expect(
        multisigMyName(multisigConfigWithNamePointer: starts[i].ref.config),
        names[i],
      );
    }
    final commitments = starts
        .map((s) => s.ref.commitments.toDartString())
        .toList();
    final shares = List.generate(
      2,
      (i) => getSecretShares(
        multisigConfigWithName: starts[i].ref.config,
        seed: starts[i].ref.seed.toDartString(),
        language: languages[i],
        machine: starts[i].ref.machine,
        commitments: commitments,
      ),
    );
    final messages = shares.map((s) => s.ref.shares.toDartString()).toList();
    final results = List.generate(
      2,
      (i) => completeKeyGen(
        multisigConfigWithName: starts[i].ref.config,
        machineAndCommitments: shares[i],
        shares: messages,
      ),
    );
    expect(
      results[0].ref.recovery.toDartString(),
      results[1].ref.recovery.toDartString(),
    );
    expect(
      List.generate(32, (i) => results[0].ref.multisig_id[i]),
      List.generate(32, (i) => results[1].ref.multisig_id[i]),
    );
    final keys = results.map((r) => r.ref.keys).toList();
    _sign(keys);

    const newNames = ['Chloé', '雪'];
    final reshareConfig = newResharerConfig(
      newThreshold: 2,
      resharers: [0, 1],
      newParticipants: newNames,
    );
    final oldStarts = keys
        .map(
          (k) => startResharer(
            serializedKeys: serializeKeys(keys: k),
            config: reshareConfig,
          ),
        )
        .toList();
    final newStarts = newNames
        .map(
          (name) => startReshared(
            newMultisigName: '次の財布🔑',
            resharerConfig: reshareConfig,
            myName: name,
            resharerStarts: oldStarts.map((s) => s.encoded).toList(),
          ),
        )
        .toList();
    for (final start in newStarts) {
      expect(
        multisigName(
          multisigConfig: encodeMultisigConfig(
            multisigConfigPointer: start.machine.ref.multisig_config$1,
          ),
        ),
        '次の財布🔑',
      );
    }
    final oldCompletes = oldStarts
        .map(
          (s) => completeResharer(
            machine: s.machine.ref,
            encryptionKeysOfResharedTo: newStarts
                .map((n) => n.encoded)
                .toList(),
          ),
        )
        .toList();
    final newCompletes = newStarts
        .map(
          (s) => completeReshared(
            prior: s.machine.ref,
            resharerCompletes: oldCompletes,
          ),
        )
        .toList();
    expect(newCompletes[0].resharedId, newCompletes[1].resharedId);
    final newKeys = newCompletes
        .map((r) => deserializeKeys(keys: r.serializedKeys))
        .toList();
    expect(
      addressForKeys(
        network: Network.Regtest,
        keys: newKeys[0],
        addressDerivationData: derivation,
        secure: true,
      ),
      addressForKeys(
        network: Network.Regtest,
        keys: keys[0],
        addressDerivationData: derivation,
        secure: true,
      ),
    );
    _sign(newKeys);
  });
}

void _sign(List<Pointer<ThresholdKeysWrapper>> keys) {
  final script = script_pubkey_for_keys(keys[0], 0, 0, false, true);
  expect(script.err, SUCCESS);
  final scriptBytes = Uint8List.fromList(
    hexStringToList(script.value.ref.toDartString()),
  );
  free_owned_string(script.value.ref);
  final config = signingConfig(keys[0], script: scriptBytes);
  final starts = keys
      .map(
        (k) => attemptSign(
          thresholdKeysWrapperPointer: k,
          signConfig: config,
          network: Network.Regtest,
        ),
      )
      .toList();
  final preprocesses = starts
      .map((s) => s.ref.preprocess.toDartString())
      .toList();
  final continued = List.generate(
    2,
    (i) => continueSign(
      machine: starts[i].ref.machine,
      preprocesses: List.generate(2, (j) => i == j ? '' : preprocesses[j]),
    ),
  );
  final shares = continued.map((s) => s.ref.preprocess.toDartString()).toList();
  final signed = List.generate(
    2,
    (i) => completeSign(
      machine: continued[i].ref.machine,
      shares: List.generate(2, (j) => i == j ? '' : shares[j]),
    ),
  );
  expect(signed[0], signed[1]);
  expect(signed[0], isNotEmpty);
}
