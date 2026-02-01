import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

class OutKeyResponse {
  final RctKey key;
  final RctKey mask;
  final bool unlocked;
  final BigInt height;
  final RctKey? txid;
  OutKeyResponse({
    required RctKey key,
    required RctKey mask,
    required this.unlocked,
    required this.height,
    required RctKey? txId,
  }) : key = key.asImmutableBytes,
       mask = mask.asImmutableBytes,
       txid = txId?.asImmutableBytes;
  factory OutKeyResponse.fromJson(Map<String, dynamic> json) {
    return OutKeyResponse(
      key: BytesUtils.fromHexString(json["key"]),
      mask: BytesUtils.fromHexString(json["mask"]),
      unlocked: json["unlocked"],
      height: BigintUtils.parse(json["height"]),
      txId: BytesUtils.fromHexString(json["txid"]),
    );
  }
}

class GetOutResponse extends DaemonBaseResponse {
  final List<OutKeyResponse> outs;

  GetOutResponse({
    required List<OutKeyResponse> outs,
    required super.credits,
    required super.status,
    required super.topHash,
    required bool super.untrusted,
  }) : outs = outs.immutable;
  GetOutResponse.fromJson(super.json)
    : outs =
          (json["outs"] as List)
              .map((e) => OutKeyResponse.fromJson(e))
              .toList(),
      super.fromJson();
}
