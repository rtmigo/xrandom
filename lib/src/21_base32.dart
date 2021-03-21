// SPDX-FileCopyrightText: (c) 2021 Art Galkin <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:meta/meta.dart';
import 'package:xrandom/src/00_jsnumbers.dart';

import '00_errors.dart';
import '00_ints.dart';

@pragma('vm:prefer-inline')
double doornikNextFloat(int u32) {
  // https://www.doornik.com/research/randomdouble.pdf

  const M_RAN_INVM32 = 2.32830643653869628906e-010;
  return u32.uint32_to_int32() * M_RAN_INVM32 + 0.5;
}

abstract class RandomBase32 implements Random {
  /// Generates a non-negative random integer uniformly distributed in the range
  /// from 0 to 0xFFFFFFFF, both inclusive.
  ///
  /// For individual algorithms, these boundaries may actually differ. For example,
  /// algorithms in the Xorshift family never return zero.
  ///
  /// It is the raw output of the generator.
  int nextRaw32();

  /// Generates a non-negative random integer uniformly distributed in the range
  /// from 0 to 2^64-1, both inclusive.
  ///
  /// This method only works on VM. If you try to execute it in JS, an
  /// [Unsupported64Error] will be thrown.
  ///
  /// The raw numbers generated by the algorithm are 32-bit. This method
  /// combines two results of [nextRaw32], placing the first number in the upper bits
  /// of the 64-bit, and the second in the lower bits.
  @pragma('vm:prefer-inline')
  int nextRaw64() {
    if (!INT64_SUPPORTED) {
      throw Unsupported64Error();
    }
    return (this.nextRaw32() << 32) | this.nextRaw32();
  }

  /// Generates a non-negative random integer uniformly distributed in the range
  /// from 0, inclusive, to 2^63, exclusive.
  @pragma('vm:prefer-inline')
  int nextRaw53() {
    return INT64_SUPPORTED
        ? nextRaw64().unsignedRightShift(11)
        : combineUpper53bitsJS(nextRaw32(), nextRaw32());
  }

  /// Generates a non-negative random integer uniformly distributed in
  /// the range from 0, inclusive, to [max], exclusive.
  ///
  /// To make the distribution uniform, we use the so-called
  /// [Debiased Modulo Once - Java Method](https://git.io/Jm0D7).
  ///
  /// This implementation is slightly faster than the standard one for
  /// all [max] values, except for [max], which are powers of two.
  @override
  int nextInt(int max) {
    if (max < 1 || max > 0xFFFFFFFF) {
      throw RangeError.range(max, 1, 0xFFFFFFFF);
    }
    int r = nextRaw32();
    int m = max - 1;
    for (int u = r; u - (r = u % max) + m < 0; u = nextRaw32()) {}
    return r;
  }

  /// Generates a random floating point value uniformly distributed
  /// in the range from 0.0, inclusive, to 1.0, exclusive.
  ///
  /// This method works faster than [nextDouble]. It sacrifices accuracy for speed.
  /// The result is mapped from a single 32-bit integer to [double].
  /// Therefore, the variability is limited by the number of possible values of
  /// such integer: 2^32 (= 4 294 967 296).
  ///
  /// This method uses the conversion suggested by J. Doornik in "Conversion of
  /// high-period random numbers to floating point" (2005).
  double nextFloat() {
    // https://www.doornik.com/research/randomdouble.pdf
    const M_RAN_INVM32 = 2.32830643653869628906e-010;
    return nextRaw32().uint32_to_int32() * M_RAN_INVM32 + 0.5;
  }

  @override
  double nextDouble() {
    return nextRaw32() * 2.3283064365386963e-10 + (nextRaw32() >> 12) * 2.220446049250313e-16;
  }

  @override
  bool nextBool() {
    // we're returning bits from higher to lower: like uint32s from int64s
    if (boolCache_prevShift == 0) {
      boolCache = nextRaw32();
      boolCache_prevShift = 31;
      return boolCache & 0x80000000 != 0;
    } else {
      assert(boolCache_prevShift > 0);
      boolCache_prevShift--;
      final result = (boolCache & (1 << boolCache_prevShift)) != 0;
      return result;
    }
  }

  @internal
  int boolCache = 0;

  @internal
  int boolCache_prevShift = 0;
}
