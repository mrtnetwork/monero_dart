import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/monero_base.dart';
import 'package:test/test.dart';

void main() {
  return txExtraPadding();
}

void txExtraPadding() {
  test("padding", () {
    {
      final data = [0];
      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 1);
      expect(decode[0].type, TxExtraTypes.padding);
      expect(decode[0].cast<TxExtraPadding>().data.length, data.length - 1);
      expect(decode[0].cast<TxExtraPadding>().toVariantSerialize(), data);
    }
    {
      final data = [0, 0];
      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 1);
      expect(decode[0].type, TxExtraTypes.padding);
      expect(decode[0].cast<TxExtraPadding>().data.length, data.length - 1);
      expect(decode[0].cast<TxExtraPadding>().toVariantSerialize(), data);
    }
    {
      final data = [0, ...List.filled(TxExtraConst.txPaddingMaxCount, 0)];
      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 1);
      expect(decode[0].type, TxExtraTypes.padding);
      expect(decode[0].cast<TxExtraPadding>().data.length, data.length - 1);
      expect(decode[0].cast<TxExtraPadding>().toVariantSerialize(), data);
    }
    {
      final data = [0, ...List.filled(TxExtraConst.txPaddingMaxCount + 1, 0)];
      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 0);
    }
  });

  test("publick key", () {
    {
      final data = BytesUtils.fromHexString(
        "011ed062a285405553705bbc59d31883279a16e4503fc68dad6ff4b70495ba8ce6",
      );
      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 1);
      expect(decode[0].type, TxExtraTypes.publicKey);
      expect(decode[0].toVariantSerialize(), data);
    }
  });
  test("nonce", () {
    {
      final data = [2, 1, 42];
      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 1);
      expect(decode[0].type, TxExtraTypes.nonce);
      expect(decode[0].toVariantSerialize(), data);
      expect(decode[0].cast<TxExtraNonce>().nonce[0], 42);
    }
  });
  test("public key and padding", () {
    {
      final data = [
        1,
        30,
        208,
        98,
        162,
        133,
        64,
        85,
        83,
        112,
        91,
        188,
        89,
        211,
        24,
        131,
        39,
        154,
        22,
        228,
        80,
        63,
        198,
        141,
        173,
        111,
        244,
        183,
        4,
        149,
        186,
        140,
        230,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ];
      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 2);
      expect(decode[0].type, TxExtraTypes.publicKey);
      expect(decode[1].type, TxExtraTypes.padding);
      expect(decode.expand((e) => e.toVariantSerialize()).toList(), data);
    }
  });

  test("public key and nonce", () {
    {
      final data = [
        1,
        30,
        208,
        98,
        162,
        133,
        64,
        85,
        83,
        112,
        91,
        188,
        89,
        211,
        24,
        131,
        39,
        154,
        22,
        228,
        80,
        63,
        198,
        141,
        173,
        111,
        244,
        183,
        4,
        149,
        186,
        140,
        230,
        2,
        1,
        42,
        1,
        30,
        208,
        98,
        162,
        133,
        64,
        85,
        83,
        112,
        91,
        188,
        89,
        211,
        24,
        131,
        39,
        154,
        22,
        228,
        80,
        63,
        198,
        141,
        173,
        111,
        244,
        183,
        4,
        149,
        186,
        140,
        230,
      ];

      final decode = MoneroTransactionHelper.extraParsing(
        data,
        errorOnFailedParsingExtras: false,
      );
      expect(decode.length, 3);
      expect(decode[0].type, TxExtraTypes.publicKey);
      expect(decode[1].type, TxExtraTypes.nonce);
      expect(decode[2].type, TxExtraTypes.publicKey);
      expect(decode.expand((e) => e.toVariantSerialize()).toList(), data);
    }
  });
}
