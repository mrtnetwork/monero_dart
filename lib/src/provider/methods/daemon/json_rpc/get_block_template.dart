import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/methods/wallet/methods/get_block_template.dart';

/// Submit a mined block to the network.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#submit_block
class DaemonRequestOnGetBlockTemplate extends MoneroDaemonRequestParam<
    DaemonOnGetBlockTemplateResponse, Map<String, dynamic>> {
  DaemonRequestOnGetBlockTemplate(
      {required this.walletAddress, required this.reserveSize});

  /// string; Address of wallet to receive coinbase
  /// transactions if block is successfully mined.
  final String walletAddress;

  /// Reserve size.
  final int reserveSize;

  @override
  String get method => "get_block_template";
  @override
  Map<String, dynamic> get params =>
      {"wallet_address": walletAddress, "reserve_size": reserveSize};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonOnGetBlockTemplateResponse onResonse(Map<String, dynamic> result) {
    return DaemonOnGetBlockTemplateResponse.fromJson(result);
  }
}
