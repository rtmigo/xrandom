// SPDX-FileCopyrightText: (c) 2021 Art Galkin <github.com/rtmigo>
// SPDX-License-Identifier: MIT
import 'dart:math';

import 'package:meta/meta.dart';

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
  /// from 1 to 0xFFFFFFFF, both inclusive.
  ///
  /// It is the raw output of the generator.
  int nextRaw32();

  /// Generates a non-negative random integer uniformly distributed in the range
  /// from 1 to 2^64-1, both inclusive.
  ///
  /// This method only works on VM. If you try to execute it in JS, an
  /// [Unsupported64Error] will be thrown.
  ///
  /// The raw numbers generated by the algorithm are 32-bit. This method
  /// combines two 32-bit numbers, placing the first number in the highest bytes
  /// of the 64-bit, and the second in the lowest bytes.
  ///
  /// Since the 32-bit generator never returns zero, after combining, neither
  /// the lowest 4 nor the highest 4 bytes of the number will be zero.
  @pragma('vm:prefer-inline')
  int nextRaw64() {
    if (!INT64_SUPPORTED) {
      throw Unsupported64Error();
    }
    return (this.nextRaw32() << 32) | this.nextRaw32();
  }

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

  //
  // REMARKS to 32's nextInt():
  //
  // The algorithm used by Dart SDK 2.12 (2021) <https://git.io/Jm0or> is
  // very similar to JDK <https://git.io/Jm0Vc>.
  //
  // O'Neil <https://git.io/Jm0D7> calls it "Debiased Modulo (Once) —
  // Java's Method" aka "Debiased Mod (x1)". Her sources contain attempts to
  // optimize modulo division here. But these attempts were not even included
  // in the article.
  //
  // Both JDK and Dart implementations have "a special treatment" for cases
  // when [max] is a power of two. Dart uses this case for speed: it returns
  // low-order bits without division. JDK uses this case to get high-order bits
  // instead low-order bits (trying to fix LCG on the fly at least for some
  // values:).
  //
  // As for now I removing the "special treatment" since I have doubts whether
  // we need to add speed optimizations for only 31 numbers out of 2^32.
  // I also have no idea how to take high-order bits fast, considering that
  // the code is possibly running in 53-bit JavaScript.
  //

  /// Generates a non-negative random floating point value uniformly distributed
  /// in the range from 0.0, inclusive, to 1.0, exclusive.
  ///
  /// This method works faster than [nextDouble]. It sacrifices accuracy for speed.
  /// The result is mapped from a single 32-bit non-zero integer to [double].
  /// Therefore, the variability is limited by the number of possible values of
  /// such integer: 2^32-1 (= 4 294 967 295).
  ///
  /// This method uses the conversion suggested by J. Doornik in "Conversion of
  /// high-period random numbers to floating point" (2005).
  double nextFloat() {
    // https://www.doornik.com/research/randomdouble.pdf
    const M_RAN_INVM32 = 2.32830643653869628906e-010;
    return nextRaw32().uint32_to_int32() * M_RAN_INVM32 + 0.5;
  }

  //
  // REMARKS to nextFloat():
  //
  // With 2.12.1 on AMD A9, there were no differences in the performance:
  //
  // | Time (lower is better) | nextFloat | nextFloatUint | nextFloatInline |
  // |------------------------|-----------|---------------|-----------------|
  // | Xorshift32             |    370    |      379      |       373       |
  //
  // nextFloat:
  //    x.uint32_to_int32()*M_RAN_INVM32 + 0.5;
  // nextFloatInline:
  //    ( (x<=0x7fffffff)?x:(x-0x100000000) )*M_RAN_INVM32 + 0.5;
  // nextFloatUint:
  //    const FACTOR = 1 / UINT32_MAX;
  //    return (x - 1) * FACTOR
  //

  @override
  double nextDouble() {
    return nextRaw32() * 2.3283064365386963e-10 + (nextRaw32() >> 12) * 2.220446049250313e-16;
  }

  //
  // REMARKS to nextDouble():
  //
  // This method is a bit slower, than ((x>>>11)*0x1.0p-53),
  // but it works in Node.js
  //
  // Vigna <https://prng.di.unimi.it/> suggests it like "аn alternative,
  // multiplication-free conversion" of uint64_t to double like that:
  //
  // static inline double to_double(uint64_t x) {
  //   const union { uint64_t i; double d; } u
  //    = { .i = UINT64_C(0x3FF) << 52 | x >> 12 };
  //   return u.d - 1.0;
  // }
  //
  // The same technique used in Chrome's JavaScript V8 <https://git.io/Jqpma>:
  //
  // static inline double ToDouble(uint64_t state0) {
  //    // Exponent for double values for [1.0 .. 2.0)
  //    static const uint64_t kExponentBits = uint64_t{0x3FF0000000000000};
  //    uint64_t random = (state0 >> 12) | kExponentBits;
  //    return bit_cast<double>(random) - 1;
  // }
  //
  // Dart does not support typecasting of this kind.
  //
  // But here is how Madsen <https://git.io/JqWCP> does it in JavaScript:
  //   t2[0] * 2.3283064365386963e-10 + (t2[1] >>> 12) * 2.220446049250313e-16;
  // or
  //   t2[0] * Math.pow(2, -32) + (t2[1] >>> 12) * Math.pow(2, -52);
  //

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

  //
  // REMARKS to nextBool():
  //
  // in dart:math it is return nextInt(2) == 0;
  // which is an equivalent of
  //   if ((2&-2)==2) return next()&(2-1);
  //
  // benchmarks 2021-03 with Xorshift32 (on Dell Seashell):
  //    Random      (from dart:math)            2424
  //    XorShift32  return nextInt(2)==0        2136
  //    XorShift32  this.next() % 2 == 0        1903
  //    XorShift32  this.next() >= 0x80000000   1821
  //    XorShift32  returning bits              1423
  //
  //
}
