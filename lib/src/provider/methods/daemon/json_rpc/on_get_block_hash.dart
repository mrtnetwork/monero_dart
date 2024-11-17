import 'package:monero_dart/src/provider/core/core.dart';

/// Look up a block's hash by its height.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#on_get_block_hash
class DaemonRequestOnGetBlockHash
    extends MoneroDaemonRequestParam<String, String> {
  DaemonRequestOnGetBlockHash(this.blockHeight);
  final BigInt blockHeight;

  @override
  String get method => "on_get_block_hash";
  @override
  Object get params => [blockHeight.toString()];
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;
}
