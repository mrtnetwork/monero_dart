import 'package:blockchain_utils/blockchain_utils.dart';

import 'basic_models.dart';

class DistributionResponse {
  static List<BigInt> _decodeRctOffsets(List<int> distribution) {
    int offset = 0;
    final List<BigInt> offsets = [];
    BigInt result = BigInt.zero;
    int shift = 0;
    while (distribution.length > offset) {
      final int byte = distribution[offset];
      offset++;

      result |= BigInt.from((byte & 0x7F)) << shift;
      shift += 7;
      if ((byte & 0x80) == 0) {
        offsets.add(result);
        result = BigInt.zero;
        shift = 0;
        continue;
      }
    }
    return offsets;
  }

  final BigInt amount;
  final int base;
  final bool binary;
  final bool compress;
  final List<BigInt> distribution;
  final int startHeight;
  const DistributionResponse({
    required this.amount,
    required this.base,
    required this.binary,
    required this.compress,
    required this.distribution,
    required this.startHeight,
  });
  factory DistributionResponse.fromJson(Map<String, dynamic> json) {
    final bool compress = json["compress"];
    final bool binary = json["binary"];
    List<BigInt> distribution = [];
    if (binary) {
      List<int> data;
      if (compress) {
        data = BytesUtils.fromHexString(json["compressed_data"]);
      } else {
        data = BytesUtils.fromHexString(json["distribution"]);
      }
      distribution = _decodeRctOffsets(data);
    } else {
      distribution =
          (json["distribution"] as List)
              .map((e) => BigintUtils.parse(e))
              .toList();
    }
    return DistributionResponse(
      amount: BigintUtils.parse(json["amount"]),
      base: IntUtils.parse(json["base"]),
      binary: binary,
      compress: json["compress"],
      distribution: distribution,
      startHeight: IntUtils.tryParse(json["start_height"]) ?? 0,
    );
  }
}

class OutputDistributionResponse extends DaemonBaseResponse {
  final List<DistributionResponse> distributions;
  OutputDistributionResponse.fromJson(super.json)
    : distributions =
          (json["distributions"] as List)
              .map((e) => DistributionResponse.fromJson(e))
              .toList(),
      super.fromJson();
}
