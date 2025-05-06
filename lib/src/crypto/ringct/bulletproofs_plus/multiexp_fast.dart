import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/models/multiexp_data.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class _StrausData {
  final List<List<EDPoint>> multiples;
  final int size;
  EDPoint at(int point, int digit) {
    return multiples[point][digit - 1];
  }

  _StrausData({required this.multiples, required this.size});

  factory _StrausData.init({required List<MultiexpData> data, int n = 0}) {
    if (n == 0) {
      n = data.length;
    }
    if (n > data.length) {
      throw const MoneroCryptoException("Bad cache base data.");
    }
    final _StrausData cache = _StrausData(
        size: n,
        multiples: List.generate(
            n,
            (_) => List.generate((1 << Multiexp.strausC) - 1,
                (_) => EDPoint.infinity(curve: Curves.curveEd25519))));
    for (int j = 0; j < n; ++j) {
      cache.multiples[j][0] = data[j].point;
      for (int i = 2; i < (1 << Multiexp.strausC); ++i) {
        final n = data[j].point + cache.at(j, i - 1);
        cache.multiples[j][i - 1] = n;
      }
    }
    return _StrausData(
        multiples: cache.multiples.map((e) => e.immutable).toImutableList,
        size: n);
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

  static List<EDPoint> _getPippenger(
      {required List<MultiexpData> data, int startOffset = 0, int? N}) {
    if (startOffset > data.length) {
      throw const MoneroCryptoException("Bad cache base data");
    }
    if (N == null || N == 0) {
      N = data.length - startOffset;
    }

    if (N > data.length - startOffset) {
      throw const MoneroCryptoException("Bad cache base data");
    }
    final List<EDPoint> cache = [];
    for (int i = 0; i < N; ++i) {
      cache.add(data[i + startOffset].point);
    }

    return cache;
  }

  static EDPoint _strausP3({required List<MultiexpData> data, int? step}) {
    if (step == null || step == 0) {
      step = 192;
    }
    final localCache = _StrausData.init(data: data);
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
    EDPoint? resp3;
    for (int startOffset = 0; startOffset < data.length; startOffset += step) {
      final int numPoints = (data.length - startOffset).clamp(0, step);
      EDPoint? bandP3;
      int i = startI;
      if (!(i < strausC)) {
        i -= strausC;
        for (int j = startOffset; j < startOffset + numPoints; ++j) {
          final int digit = (digits[j * 64 + i ~/ 4]);

          if (digit != 0) {
            final gecCached = localCache.at(j, digit);
            if (bandP3 == null) {
              bandP3 = gecCached;
            } else {
              bandP3 += gecCached;
            }
          }
        }
      }
      while (!(i < strausC)) {
        EDPoint p1 = bandP3!;

        for (int j = 0; j < strausC; ++j) {
          p1 = p1.doublePoint();
          if (j == strausC - 1) {
            bandP3 = p1;
          }
        }
        i -= strausC;
        for (int j = startOffset; j < startOffset + numPoints; ++j) {
          final int digit = (digits[j * 64 + i ~/ 4]);
          if (digit != 0) {
            bandP3 = bandP3! + localCache.at(j, digit);
          }
        }
      }
      if (resp3 == null) {
        resp3 = bandP3;
      } else {
        resp3 += bandP3!;
      }
    }
    return resp3!;
  }

  static EDPoint _addPoint(EDPoint p3, EDPoint other) {
    return p3 + other;
  }

  static EDPoint straus({required List<MultiexpData> data, int? step}) {
    return _strausP3(data: data, step: step);
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

  static EDPoint pippenger(
      {required List<MultiexpData> data, int? cacheSize, int? c}) {
    return _pippengerP3(data: data, cacheSize: cacheSize, c: c);
  }

  static EDPoint _pippengerP3(
      {required List<MultiexpData> data, int? cacheSize, int? c}) {
    cacheSize ??= 0;
    if (c == null || c == 0) {
      c = getPippengerC(data.length);
    }
    EDPoint result =
        EDPoint.fromBytes(curve: Curves.curveEd25519, data: RCT.identity());
    bool resultInit = false;
    final List<EDPoint?> buckets = List.filled(1 << c, null);
    final List<bool> bucketsInit = List.filled(1 << 9, false);
    final localCache = _getPippenger(data: data);

    final localCache2 = data.length > cacheSize
        ? _getPippenger(data: data, startOffset: cacheSize)
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
        EDPoint p2 = result;
        for (int i = 0; i < c; ++i) {
          final EDPoint p1 = p2.doublePoint();
          if (i == c - 1) {
            result = p1;
          } else {
            p2 = p1;
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

        assert(bucket < (1 << c), "Bucket overflow");

        if (bucketsInit[bucket]) {
          if (i < cacheSize) {
            buckets[bucket] = _addPoint(buckets[bucket]!, localCache[i]);
          } else {
            buckets[bucket] =
                _addPoint(buckets[bucket]!, localCache2![i - cacheSize]);
          }
        } else {
          buckets[bucket] = data[i].point;
          bucketsInit[bucket] = true;
        }
      }

      EDPoint pail = EDPoint.infinity(curve: Curves.curveEd25519);
      bool pailInit = false;
      for (int i = (1 << c) - 1; i > 0; --i) {
        if (bucketsInit[i]) {
          if (pailInit) {
            pail = _addPoint(pail, buckets[i]!);
          } else {
            pail = buckets[i]!;
            pailInit = true;
          }
        }
        if (pailInit) {
          if (resultInit) {
            result = _addPoint(result, pail);
          } else {
            result = pail;
            resultInit = true;
          }
        }
      }
    }
    return result;
  }
}
