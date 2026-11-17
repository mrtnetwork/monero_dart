import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

import 'utils.dart';

List<MoneroFeePrority> getFeeProrities(BigInt baseFee, List<BigInt>? fees) {
  final int length = fees?.length ?? 0;
  if (length == 0) {
    return [MoneroFeePrority.defaultPriority];
  }
  return MoneroFeePrority.values.sublist(0, IntUtils.min(4, length + 1));
}

void addressTest() {
  test("IAddress encoding", () {
    final addr = MoneroIntegratedAddress.fromPubKeys(
      pubSpendKey:
          ED25519MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.toBytes(),
      pubViewKey:
          ED25519MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.toBytes(),
      paymentId: QuickCrypto.generateRandom(length: 8),
    );
    expect(
      addr,
      MoneroAddress.deserializeIAddress(bytes: addr.encodeAsIAddress()),
    );
  });
  test("IAddress encoding", () {
    final addr = MoneroIntegratedAddress.fromPubKeys(
      pubSpendKey:
          ED25519MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.toBytes(),
      pubViewKey:
          ED25519MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.toBytes(),
      paymentId: QuickCrypto.generateRandom(length: 8),
      network: MoneroNetwork.stagenet,
    );
    expect(
      addr,
      MoneroAddress.deserializeIAddress(bytes: addr.encodeAsIAddress()),
    );
  });
  test("IAddress encoding", () {
    final addr = MoneroAccountAddress.fromPubKeys(
      pubSpendKey:
          ED25519MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.toBytes(),
      pubViewKey:
          ED25519MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.toBytes(),
      network: MoneroNetwork.testnet,
    );
    expect(
      addr,
      MoneroAddress.deserializeIAddress(bytes: addr.encodeAsIAddress()),
    );
  });
}

void main() {
  MoneroTestApi.runTest(addressTest, "Address");
}
