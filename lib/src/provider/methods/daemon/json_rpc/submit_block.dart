import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Submit a mined block to the network.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#submit_block
class DaemonRequestSubmitBlock
    extends MoneroDaemonRequestParam<String, String> {
  DaemonRequestSubmitBlock(List<String> blockBlobData)
    : blockBlobData = blockBlobData.immutable;

  ///  array of strings; list of block blobs which have been mined.
  ///  See get_block_template to get a blob on which to mine.
  final List<String> blockBlobData;

  @override
  String get method => "submit_block";
  @override
  List<String> get params => blockBlobData;
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
}
