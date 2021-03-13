![Generic badge](https://img.shields.io/badge/status-draft-red.svg)
[![Actions Status](https://github.com/rtmigo/xorshift/workflows/unittest/badge.svg?branch=master)](https://github.com/rtmigo/xorshift/actions)
![Generic badge](https://img.shields.io/badge/tested_on-Windows_|_MacOS_|_Ubuntu-blue.svg)

# [xorshift](https://github.com/rtmigo/xorshift)

This library implements [Xorshift](https://en.wikipedia.org/wiki/Xorshift) random number generators
in native Dart.

Xorshift algorithms are known among the **fastest random number generators**, requiring very small
code and state.

# Usage

All classes implement the standard `Random` from `dart:math`, so they can be used in the same way.

``` dart
import 'package:xorshift/xorshift.dart';

Random random = Xorshift();
print(random.nextInt(100));
print(random.nextDouble());
```

In addition, they have a `next()` method that returns an `int` with no range restrictions. For some
algorithms this is a 32-bit number, for another a 64-bit number.

# Deterministic

All classes have a `deterministic` method. By creating an object with this method, you end up with a
generator that produces the same sequence of numbers every time.

``` dart
test('my test', () {
    final sameValuesEachTime = Xorshift.deterministic();
    // wow, results based on randoms are predictable now
    expect(sameValuesEachTime.nextInt(1000), 543);
    expect(sameValuesEachTime.nextInt(1000), 488);
    expect(sameValuesEachTime.nextInt(1000), 284);    
});    
```

You can achieve the same by creating a system `Random` with a `seed` argument. However, the
system `Random` implementation may change with the next Dart update. As a result, with the
same seed value, you will get different numbers.

In contrast to this, Xorshift is a very specific algorithm. And the library is built with an emphasis
on maximum predictability (funny, right?) Therefore, the predictability of the Xorshift's `deterministic`
sequences can be relied upon.

# Classes

``` dart 
Xorshift();         // xorshift128+ by Sebastiano Vigna [2015] 
Xorshift32();       // xorshift32 by George Marsaglia [2003] 
Xorshift64();       // xorshift64 by George Marsaglia [2003]
Xorshift128();      // xorshift128 by George Marsaglia [2003]
Xorshift128Plus();  // the same class as Xorshift()
```

# Compatibility

The library has been thoroughly tested to match reference numbers generated by C algorithms. The
sources in C are taken directly from scientific articles by George Marsaglia and Sebastiano Vigna,
the inventors of the algorithms. The Xorshift128+ results are also matched to reference values from
JavaScript [xorshift](https://github.com/AndreasMadsen/xorshift) library, that tested the 128+
similarly.

The library will work on all the platforms where `int` represents a 64-bit signed integer. That is,
on all platforms except Web/JavaScript.

Unit testing is done in the GitHub Actions cloud on Windows, Ubuntu and macOS in VM and NODE m.

| Class                          | VM    | JavaScript |
|--------------------------------|-------|------------|
| Xorshift32                     | yes   | yes        |
| Xorshift64                     | yes   |            |
| Xorshift (aka Xorshift128)     | yes   | yes        |
| Xorshift128Plus                | yes   |            |