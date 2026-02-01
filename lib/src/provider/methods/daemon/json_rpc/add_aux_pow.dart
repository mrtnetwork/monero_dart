import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Easily enable merge mining with MoneroAccount without requiring software that manually
/// alters the extra field in the coinbase tx to include the merkle root of the aux blocks.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#add_aux_pow
class DaemonRequestAddAuxPow
    extends
        MoneroDaemonRequestParam<
          DaemonAddAuxPowResponse,
          Map<String, dynamic>
        > {
  DaemonRequestAddAuxPow({
    required this.blocktemplateBlob,
    required this.auxPow,
  });

  final String blocktemplateBlob;
  final List<DaemonAuxPowParams> auxPow;

  @override
  String get method => "add_aux_pow";
  @override
  Map<String, dynamic> get params => {
    "blocktemplate_blob": blocktemplateBlob,
    "aux_pow": auxPow.map((e) => e.toJson()).toList(),
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonAddAuxPowResponse onResonse(Map<String, dynamic> result) {
    return DaemonAddAuxPowResponse.fromJson(result);
  }
}
