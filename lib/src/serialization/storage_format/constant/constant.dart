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
    _version,
  ];
  static const int arrayFalgs = 0x80;
  static const int entryNameLength = 255;
  static const int varintMaxOnByte = 63;
  static const int varintMaxTwoByte = 16383;
  static const int varintMaxFourByte = 1073741823;

  static const int portableRawSizeMarkMask = 0x03;
  static const int portableRawSizeMarkByte = 0;
  static const int portableRawSizeMarkWord = 1;
  static const int portableRawSizeMarkDword = 2;
  static const int portableRawSizeMarkInt64 = 3;
}
