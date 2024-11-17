import 'package:monero_dart/src/crypto/models/ct_key.dart';

/// represents a 32-byte key.
typedef RctKey = List<int>;

/// is a list of `RctKey` (List of 32-byte keys)
typedef Key64 = List<RctKey>;

/// is a list of `RctKey`, representing a collection of 32-byte keys.
typedef KeyV = List<RctKey>;

/// `KeyM` is a list of `KeyV`, representing a more complex structure of 32-byte keys.
typedef KeyM = List<KeyV>;
typedef CtKeyV = List<CtKey>;
typedef CtKeyM = List<CtKeyV>;
typedef Bits = List<int>;
