import 'dart:ffi';
import 'dart:typed_data';

import 'package:frostdart/frostdart.dart';
import 'package:frostdart/frostdart_bindings_generated.dart';
import 'package:frostdart/output.dart';

const vectorKeys =
    '09000000736563703235366b31020003000100'
    '08f89ffe80ac94dcb920c26f3f46140bfc7f95b493f8310f5fc1ea2b01f4254c'
    '026baee4bf7d4b9c4567dfff6f3c2c76df5c082e9320cd8187d6ab5965bc5a119a'
    '03dacc9463e5186f3c81ae1b314f7b09001a22b28bb56ad0abd3f376818f9604ab'
    '031404710e938032db0d4f6a4cd20ae37384be98ba9fe05b42d139361202b391e6';

const derivation = (account: 0, change: false, index: 0, secure: true);
const destination = 'bcrt1qdc89v44888fjwus4wke8kppj6043h9698wf8uv';
final inputHash = Uint8List.fromList(List.generate(32, (i) => i));
// P2TR fixture for configuration parsing.
final inputScript = Uint8List.fromList([0x51, 0x20, ...List.filled(32, 1)]);
String signingConfig(
  Pointer<ThresholdKeysWrapper> keys, {
  Uint8List? hash,
  Uint8List? script,
}) => newSignConfig(
  thresholdKeysWrapperPointer: keys,
  network: Network.Regtest,
  outputs: [
    Output(
      hash: hash ?? inputHash,
      vout: 1,
      value: 200000000,
      scriptPubKey: script ?? inputScript,
      addressDerivationData: derivation,
    ),
  ],
  paymentAddresses: [destination],
  paymentAmounts: [500000],
  change: destination,
  feePerWeight: 3000,
);
