import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class MultiexpData {
  final RctKey scalar;
  final EDPoint point;
  MultiexpData({required List<int> scalar, required this.point})
      : scalar = scalar.asImmutableBytes;
}
