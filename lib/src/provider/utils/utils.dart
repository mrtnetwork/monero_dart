import 'package:blockchain_utils/blockchain_utils.dart';

class ProviderUtils {
  static List<String> parseBlockBinaryResponse(String hex) {
    if (hex.isEmpty) return [];
    const int blockLengthHex = 64;
    if (!StringUtils.isHexBytes(hex)) {
      throw BuError(DefaultErrorType.invalidArgument, "Invalid hex string.");
    }
    if (hex.length % blockLengthHex != 0) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid block ids response bytes.",
      );
    }
    final List<String> blockIds = [];
    int offset = 0;
    while (offset < hex.length) {
      blockIds.add(hex.substring(offset, offset + blockLengthHex));
      offset += blockLengthHex;
    }
    return blockIds;
  }
}
