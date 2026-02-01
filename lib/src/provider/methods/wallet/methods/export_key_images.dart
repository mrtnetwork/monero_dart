import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Export a signed set of key images.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#export_key_images
class WalletRequestExportKeyImages
    extends
        MoneroWalletRequestParam<
          WalletRPCExportKeyImagesResponse,
          Map<String, dynamic>
        > {
  WalletRequestExportKeyImages({this.all});

  /// If true, export all key images. Otherwise, export key images since the last export. (default = false)
  final bool? all;

  @override
  String get method => "export_key_images";
  @override
  Map<String, dynamic> get params => {"all": all};

  @override
  WalletRPCExportKeyImagesResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCExportKeyImagesResponse.fromJson(result);
  }
}
