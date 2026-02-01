import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Check if outputs have been spent using the key image associated with the output.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#is_key_image_spent
class DaemonRequestIsKeyImageSpent
    extends
        MoneroDaemonRequestParam<
          DaemonIsKeyImageSpentResponse,
          Map<String, dynamic>
        > {
  DaemonRequestIsKeyImageSpent(List<String> keyImages)
    : keyImages = keyImages.immutable;

  final List<String> keyImages;

  @override
  String get method => "is_key_image_spent";
  @override
  Map<String, dynamic> get params => {"key_images": keyImages};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonIsKeyImageSpentResponse onResonse(Map<String, dynamic> result) {
    return DaemonIsKeyImageSpentResponse.fromJson(result);
  }
}
