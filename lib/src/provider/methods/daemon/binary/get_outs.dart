import 'package:blockchain_utils/helper/helper.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/methods/wallet/methods/get_out_response.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get outputs.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_outs
class DaemonRequestGetOuts
    extends MoneroDaemonRequestParam<GetOutResponse, Map<String, dynamic>> {
  DaemonRequestGetOuts({
    required List<DaemonGetOutRequestParams> outputs,
    this.getTxId = false,
  }) : outputs = outputs.immutable;

  final List<DaemonGetOutRequestParams> outputs;

  ///  a txid will included for each output in the response.
  final bool getTxId;

  @override
  String get method => "get_outs.bin";
  @override
  Map<String, dynamic> get params => {
    "outputs": outputs.map((e) => e.toJson()).toList(),
    "get_txid ": getTxId,
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.binary;

  @override
  GetOutResponse onResonse(Map<String, dynamic> result) {
    return GetOutResponse.fromJson(result);
  }
}
