class MoneroSerializationConst {
  static const int _version = 0x01;
  static const List<int> signaturePartBAndVersionVersion = [
    1,
    17,
    1,
    1,
    1,
    1,
    2,
    1,
    _version
  ];
  static const int arrayFalgs = 0x80;
  static const int entryNameLength = 255;
  static const int varintMaxOnByte = 63;
  static const int varintMaxTwoByte = 16383;
  static const int varintMaxFourByte = 1073741823;
  static final BigInt varintBigIntMaxOnByte = BigInt.from(varintMaxOnByte);
  static final BigInt varintBigIntMaxTwoByte = BigInt.from(varintMaxTwoByte);
  static final BigInt varintBigIntMaxFourByte = BigInt.from(varintMaxFourByte);
  static final BigInt varintBigIntMaxEightByte =
      BigInt.parse("4611686018427387903");

  static const int portableRawSizeMarkMask = 0x03;
  static const int portableRawSizeMarkByte = 0;
  static const int portableRawSizeMarkWord = 1;
  static const int portableRawSizeMarkDword = 2;
  static const int portableRawSizeMarkInt64 = 3;
  static final BigInt portableRawSizeMarkMaskBigInt =
      BigInt.from(portableRawSizeMarkMask);
  static final BigInt portableRawSizeMarkByteBigInt =
      BigInt.from(portableRawSizeMarkByte);
  static final BigInt portableRawSizeMarkWordBigInt =
      BigInt.from(portableRawSizeMarkWord);
  static final BigInt portableRawSizeMarkDwordBigInt =
      BigInt.from(portableRawSizeMarkDword);
  static final BigInt portableRawSizeMarkInt64BigInt = BigInt.from(3);
}
