class MoneroMultisigConst {
  static const List<int> hashKeyMultisig = [
    0x4d,
    0x75,
    0x6c,
    0x74,
    0x69,
    0x73,
    0x69,
    0x67,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00
  ];
  static const String multisigKexMsgV2Magic1 = "MultisigxV2R1";
  static const String multisigKexMsgV2MagicN = "MultisigxV2Rn";
  static const List<int> hashKeyMultisigKeyAggregation = [
    77,
    117,
    108,
    116,
    105,
    115,
    105,
    103,
    95,
    107,
    101,
    121,
    95,
    97,
    103,
    103
  ];
  static const int prefixLength = 13;
  static const int kAlphaComponents = 2;
  static const int multisigMaxSigners = 16;
}
