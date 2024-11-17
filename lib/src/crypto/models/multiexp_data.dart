import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class MultiexpData {
  final RctKey scalar;
  final GroupElementP3 point;
  MultiexpData({required List<int> scalar, required this.point})
      : scalar = scalar.asImmutableBytes;

  Map<String, dynamic> toJson() {
    return {"scalar": BytesUtils.toHexString(scalar), "point": point.toJson()};
  }

  factory MultiexpData.fromJson(Map<String, dynamic> json) {
    return MultiexpData(
        scalar: BytesUtils.fromHexString(json["scalar"]),
        point: GroupElementP3.fromJson(json["point"]));
  }
}
