import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';

class ProviderUtils {
  static List<String> parseBlockBinaryResponse(String hex) {
    const int blockLengthHex = 64;
    if (!StringUtils.isHexBytes(hex)) {
      throw const DartMoneroPluginException("Invalid hex string.");
    }
    final toBytes = BytesUtils.fromHexString(hex);
    if (toBytes.length % blockLengthHex != 0) {
      throw const DartMoneroPluginException("Invalid block response bytes.");
    }
    final List<String> blockIds = [];
    int start = 0;
    while (start < toBytes.length) {
      blockIds.add(hex.substring(start, start + blockLengthHex));
      start += blockLengthHex;
    }
    return blockIds;
  }
}
