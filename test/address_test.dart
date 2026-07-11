import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

List<MoneroFeePrority> getFeeProrities(BigInt baseFee, List<BigInt>? fees) {
  final int length = fees?.length ?? 0;
  if (length == 0) {
    return [MoneroFeePrority.defaultPriority];
  }
  return MoneroFeePrority.values.sublist(0, IntUtils.min(4, length + 1));
}

void main() {
  test("IAddress encoding", () {
    final addr = MoneroIntegratedAddress.fromPubKeys(
      pubSpendKey:
          MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.compressed,
      pubViewKey:
          MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.compressed,
      paymentId: QuickCrypto.generateRandom(8),
    );
    expect(
      addr,
      MoneroAddress.deserializeIAddress(bytes: addr.encodeAsIAddress()),
    );
  });
  test("IAddress encoding", () {
    final addr = MoneroIntegratedAddress.fromPubKeys(
      pubSpendKey:
          MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.compressed,
      pubViewKey:
          MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.compressed,
      paymentId: QuickCrypto.generateRandom(8),
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
          MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.compressed,
      pubViewKey:
          MoneroPrivateKey.fromBip44(
            QuickCrypto.generateRandom(),
          ).publicKey.compressed,
      network: MoneroNetwork.testnet,
    );
    expect(
      addr,
      MoneroAddress.deserializeIAddress(bytes: addr.encodeAsIAddress()),
    );
  });
}
