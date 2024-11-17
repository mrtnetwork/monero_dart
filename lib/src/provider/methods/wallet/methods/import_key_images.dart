import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Import signed key images list and verify their spent status.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#import_key_images
class WalletRequestImportKeyImages extends MoneroWalletRequestParam<
    WalletRPCImportKeyImagesResponse, Map<String, dynamic>> {
  WalletRequestImportKeyImages(
      {required this.offset, required this.signedKeyImages});
  final int offset;
  final List<WalletRPCSignedKeyImagesParam> signedKeyImages;

  @override
  String get method => "import_key_images";
  @override
  Map<String, dynamic> get params => {
        "offset": offset,
        "signed_key_images": signedKeyImages.map((e) => e.toJson()).toList()
      };

  @override
  WalletRPCImportKeyImagesResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCImportKeyImagesResponse.fromJson(result);
  }
}
