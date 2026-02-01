import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/serializer.dart';
import 'package:monero_dart/src/serialization/storage_format/types/types.dart';

/// Custom implements for encoding data
abstract class MoneroStorageContainer {
  final MoneroStorageTypes type;
  const MoneroStorageContainer(this.type);
  List<int> serialize();
  bool get hasValue;
}

class MoneroStorageBinary extends MoneroStorageContainer {
  final List<int> data;
  MoneroStorageBinary._(List<int> data)
    : data = data.asImmutableBytes,
      super(MoneroStorageTypes.string);
  factory MoneroStorageBinary.fromBytes(List<int> data) {
    return MoneroStorageBinary._(data);
  }
  factory MoneroStorageBinary.fromListOfHex(List<String> hex) {
    return MoneroStorageBinary._(
      hex.map((e) => BytesUtils.fromHexString(e)).expand((e) => e).toList(),
    );
  }

  @override
  List<int> serialize() {
    return [...MoneroStorageSerializer.encodeVarintInt(data.length), ...data];
  }

  @override
  bool get hasValue => data.isNotEmpty;
}
