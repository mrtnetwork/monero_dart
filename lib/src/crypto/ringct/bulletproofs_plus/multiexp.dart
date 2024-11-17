import 'package:blockchain_utils/crypto/crypto/cdsa/crypto_ops/crypto_ops.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/models/multiexp_data.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class StrausCachedData {
  final List<List<GroupElementCached>> multiples;
  final int size;
  GroupElementCached at(int point, int digit) {
    return multiples[point][digit - 1];
  }

  StrausCachedData(
      {required List<List<GroupElementCached>> multiples, required this.size})
      : multiples = multiples.map((e) => e.immutable).toList().immutable;

  factory StrausCachedData.init({required List<MultiexpData> data, int n = 0}) {
    if (n == 0) {
      n = data.length;
    }
    if (n > data.length) {
      throw const MoneroCryptoException("Bad cache base data.");
    }
    final GroupElementP1P1 p1 = GroupElementP1P1();
    final GroupElementP3 p3 = GroupElementP3();
    final StrausCachedData cache = StrausCachedData(
        size: n,
        multiples: List.generate(
            n,
            (_) => List.generate(
                (1 << Multiexp.strausC) - 1, (_) => GroupElementCached())));
    for (int j = 0; j < n; ++j) {
      CryptoOps.geP3ToCached(cache.at(j, 1), data[j].point);
      for (int i = 2; i < (1 << Multiexp.strausC); ++i) {
        CryptoOps.geAdd(p1, data[j].point, cache.at(j, i - 1));
        CryptoOps.geP1P1ToP3(p3, p1);
        CryptoOps.geP3ToCached(cache.at(j, i), p3);
      }
    }
    return cache;
  }
}

class Multiexp {
  static const int strausC = 4;
  static bool _isLowerThan(List<int> k0, List<int> k1) {
    for (int n = 31; n >= 0; --n) {
      if (k0[n] < k1[n]) {
        return true;
      }
      if (k0[n] > k1[n]) {
        return false;
      }
    }
    return false;
  }

  static List<int> _pow2(int n) {
    if (n >= 256) {
      throw const MoneroCryptoException("Invalid _pow2 argument");
    }
    final List<int> res = RCTConst.z.clone();
    res[n >> 3] |= 1 << (n & 7);
    return res;
  }

  static List<GroupElementCached> pippengerInitCache(
      {required List<MultiexpData> data, int startOffset = 0, int? N}) {
    if (startOffset > data.length) {
      throw Exception("Bad cache base data");
    }
    if (N == null || N == 0) {
      N = data.length - startOffset;
    }

    if (N > data.length - startOffset) {
      throw Exception("Bad cache base data");
    }
    final List<GroupElementCached> cache =
        List.generate(N, (_) => GroupElementCached());
    for (int i = 0; i < N; ++i) {
      CryptoOps.geP3ToCached(cache[i], data[i + startOffset].point);
    }

    return cache;
  }

  static GroupElementP3 _strausP3(
      {required List<MultiexpData> data,
      StrausCachedData? localCache,
      int? step}) {
    if (step == null || step == 0) {
      step = 192;
    }
    if (localCache != null && localCache.size < data.length) {
      throw const MoneroCryptoException("Cache is too small");
    }
    localCache ??= StrausCachedData.init(data: data);
    final GroupElementCached cached = GroupElementCached();
    final GroupElementP1P1 p1 = GroupElementP1P1();
    final digits = List<int>.filled(64 * data.length, 0);
    for (int j = 0; j < data.length; j++) {
      final bytes = data[j].scalar;
      for (int i = 0; i < 64; i += 2) {
        digits[j * 64 + i] = bytes[i ~/ 2] & 0xf;
        digits[j * 64 + i + 1] = bytes[i ~/ 2] >> 4;
      }
    }
    List<int> maxScalar = RCT.zero();
    for (int i = 0; i < data.length; i++) {
      if (_isLowerThan(maxScalar, data[i].scalar)) {
        maxScalar = data[i].scalar;
      }
    }
    int startI = 0;
    while (startI < 256 && !_isLowerThan(maxScalar, _pow2(startI))) {
      startI += strausC;
    }
    final GroupElementP3 resp3 = RCTConst.identityP3.clone();
    for (int startOffset = 0; startOffset < data.length; startOffset += step) {
      final int numPoints = (data.length - startOffset).clamp(0, step);
      final GroupElementP3 bandP3 = RCTConst.identityP3.clone();
      int i = startI;
      if (!(i < strausC)) {
        i -= strausC;
        for (int j = startOffset; j < startOffset + numPoints; ++j) {
          final int digit = (digits[j * 64 + i ~/ 4]);

          if (digit != 0) {
            final gecCached = localCache.at(j, digit);
            CryptoOps.geAdd(p1, bandP3, gecCached);
            CryptoOps.geP1P1ToP3(bandP3, p1);
          }
        }
      }
      while (!(i < strausC)) {
        final GroupElementP2 p2 = GroupElementP2();
        CryptoOps.geP3ToP2(p2, bandP3);

        for (int j = 0; j < strausC; ++j) {
          final GroupElementP1P1 p1 = GroupElementP1P1();
          CryptoOps.geP2Dbl(p1, p2);

          if (j == strausC - 1) {
            CryptoOps.geP1P1ToP3(bandP3, p1);
          } else {
            CryptoOps.geP1P1ToP2(p2, p1);
          }
        }
        i -= strausC;
        for (int j = startOffset; j < startOffset + numPoints; ++j) {
          final int digit = (digits[j * 64 + i ~/ 4]);
          if (digit != 0) {
            CryptoOps.geAdd(p1, bandP3, localCache.at(j, digit));
            CryptoOps.geP1P1ToP3(bandP3, p1);
          }
        }
      }

      CryptoOps.geP3ToCached(cached, bandP3);
      CryptoOps.geAdd(p1, resp3, cached);
      CryptoOps.geP1P1ToP3(resp3, p1);
    }
    return resp3;
  }

  static void _addCached(GroupElementP3 p3, GroupElementCached other) {
    final GroupElementP1P1 p1 = GroupElementP1P1();
    CryptoOps.geAdd(p1, p3, other);
    CryptoOps.geP1P1ToP3(p3, p1);
  }

  static void _addP3(GroupElementP3 p3, GroupElementP3 other) {
    final GroupElementCached cached = GroupElementCached();
    CryptoOps.geP3ToCached(cached, other);
    _addCached(p3, cached);
  }

  static List<int> straus(
      {required List<MultiexpData> data,
      StrausCachedData? localCache,
      int? step}) {
    final res = _strausP3(data: data, localCache: localCache, step: step);
    return CryptoOps.geP3Tobytes_(res);
  }

  static int getPippengerC(int n) {
    if (n <= 13) return 2;
    if (n <= 29) return 3;
    if (n <= 83) return 4;
    if (n <= 185) return 5;
    if (n <= 465) return 6;
    if (n <= 1180) return 7;
    if (n <= 2295) return 8;
    return 9;
  }

  static int _isBitSet(RctKey k, int n) {
    if (n >= 256) return 0;
    return k[n >> 3] & (1 << (n & 7));
  }

  static List<int> pippenger(
      {required List<MultiexpData> data,
      required List<GroupElementCached>? localCache,
      int? cacheSize,
      int? c}) {
    final GroupElementP3 res = _pippengerP3(
        data: data, localCache: localCache, cacheSize: cacheSize, c: c);
    return CryptoOps.geP3Tobytes_(res);
  }

  static GroupElementP3 _pippengerP3(
      {required List<MultiexpData> data,
      required List<GroupElementCached>? localCache,
      int? cacheSize,
      int? c}) {
    cacheSize ??= localCache?.length ?? 0;
    if (c == null || c == 0) {
      c = getPippengerC(data.length);
    }
    GroupElementP3 result = RCTConst.identityP3.clone();
    bool resultInit = false;
    final List<GroupElementP3> buckets =
        List.generate(1 << c, (_) => GroupElementP3());
    final List<bool> bucketsInit = List.filled(1 << 9, false);
    if (localCache?.isEmpty ?? true) {
      localCache = pippengerInitCache(data: data);
    }

    final localCache2 = data.length > cacheSize
        ? pippengerInitCache(data: data, startOffset: cacheSize)
        : null;

    List<int> maxScalar = RCT.zero();
    for (int i = 0; i < data.length; i++) {
      if (_isLowerThan(maxScalar, data[i].scalar)) {
        maxScalar = data[i].scalar.clone();
      }
    }
    int groups = 0;
    while (groups < 256 && !_isLowerThan(maxScalar, _pow2(groups))) {
      ++groups;
    }
    groups = (groups + c - 1) ~/ c;
    for (int k = groups; k-- > 0;) {
      if (resultInit) {
        final GroupElementP2 p2 = GroupElementP2();
        CryptoOps.geP3ToP2(p2, result);
        for (int i = 0; i < c; ++i) {
          final GroupElementP1P1 p1 = GroupElementP1P1();
          CryptoOps.geP2Dbl(p1, p2);
          if (i == c - 1) {
            CryptoOps.geP1P1ToP3(result, p1);
          } else {
            CryptoOps.geP1P1ToP2(p2, p1);
          }
        }
      }

      for (int i = 0; i < 1 << c; i++) {
        bucketsInit[i] = false; // Set each element to false
      }

      for (int i = 0; i < data.length; i++) {
        int bucket = 0;

        for (int j = 0; j < c; j++) {
          if (_isBitSet(data[i].scalar, k * c + j) != 0) {
            bucket |= 1 << j;
          }
        }

        if (bucket == 0) continue;

        // Assuming CHECK_AND_ASSERT_THROW_MES is replaced by a simple assertion in Dart
        assert(bucket < (1 << c), "Bucket overflow");

        if (bucketsInit[bucket]) {
          if (i < cacheSize) {
            _addCached(buckets[bucket], localCache![i]);
          } else {
            _addCached(buckets[bucket], localCache2![i - cacheSize]);
          }
        } else {
          buckets[bucket] = data[i].point.clone();
          bucketsInit[bucket] = true;
        }
      }

      GroupElementP3 pail = GroupElementP3();
      bool pailInit = false;
      for (int i = (1 << c) - 1; i > 0; --i) {
        if (bucketsInit[i]) {
          if (pailInit) {
            _addP3(pail, buckets[i]);
          } else {
            pail = buckets[i].clone();
            pailInit = true;
          }
        }
        if (pailInit) {
          if (resultInit) {
            _addP3(result, pail);
          } else {
            result = pail.clone();
            resultInit = true;
          }
        }
      }
    }
    return result;
  }
}
