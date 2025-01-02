import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Generate a block and specify the address to receive the coinbase reward.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#generateblocks
class DaemonRequestGenerateBlocks extends MoneroDaemonRequestParam<
    DaemonGenerateBlockResponse, Map<String, dynamic>> {
  DaemonRequestGenerateBlocks(
      {required this.amountOfBlocks,
      required this.walletAddress,
      required this.prevBlock,
      required this.startingNonce});

  /// number of blocks to be generated.
  final int amountOfBlocks;

  /// address to receive the coinbase reward.
  final String walletAddress;
  final String prevBlock;

  /// Increased by miner until it finds a matching result that solves a block
  final int startingNonce;

  @override
  String get method => "generateblocks";
  @override
  Map<String, dynamic> get params => {
        "amount_of_blocks": amountOfBlocks,
        "wallet_address": walletAddress,
        "prev_block": prevBlock,
        "starting_nonce": startingNonce
      };
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonGenerateBlockResponse onResonse(Map<String, dynamic> result) {
    return DaemonGenerateBlockResponse.fromJson(result);
  }
}
