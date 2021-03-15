[![Actions Status](https://github.com/rtmigo/xrandom/workflows/unittest/badge.svg?branch=master)](https://github.com/rtmigo/xrandom/actions)
![Generic badge](https://img.shields.io/badge/tested_on-Windows_|_MacOS_|_Ubuntu-blue.svg)
![Generic badge](https://img.shields.io/badge/tested_on-VM_|_JS-blue.svg)
[![Pub Package](https://img.shields.io/pub/v/xrandom.svg)](https://pub.dev/packages/xrandom)

# [xrandom](https://github.com/rtmigo/xrandom)

Classes that implement all-purpose, rock-solid random number generators.

Library priorities:
- perfect match of generated numbers on all platforms
- performance
- quality of the numbers produced

Namely, the [Xoshiro](https://prng.di.unimi.it/) for **quality** and 
[Xorshift](https://en.wikipedia.org/wiki/Xorshift) for **speed**.

# Speed

Generating 50 million of random numbers with AOT-compiled binary. 

| Time (lower is better) | nextInt | nextDouble | nextBool |
|------------------------|---------|------------|----------|
| Random (dart:math)     |  1172   |    1541    |   1134   |
| Xorshift32             |   732   |    1122    |   718    |


# Simplicity

It's compatible with the standard [`Random`](https://api.dart.dev/stable/2.12.1/dart-math/Random-class.html)

``` dart
import 'package:xrandom/xrandom.dart';

Random xrandom = Xorshift32();

var a = xrandom.nextBool(); 
var b = xrandom.nextDouble();
var c = xrandom.nextInt(n);
```

# Determinism

Xrandom's classes have a `deterministic` method. By creating the object like that, you'll get same 
sequence of numbers every time.

``` dart
test('my test', () {
    final xrandom = Xorshift32.deterministic();
    // run this test twice ;)
    expect(xrandom.nextInt(1000), 119);
    expect(xrandom.nextInt(1000), 240);
    expect(xrandom.nextInt(1000), 369);    
});    
```

You can achieve the same determinism by creating the `Random` with a `seed` argument. However, this does
not protect you from `dart:math` implementation updates.

In contrast to `dart:math`, `xrandom` uses **xorshift32**, a very specific algorithm. Therefore, the predictability of the
Xrandom's `deterministic`
sequences can be relied upon. *(but not until the library reaches stable release status)*



# Compatibility

You can safely **use any classes on mobile and desktop** platforms. 

However, if you also target **JavaScript** (Web, Node.js), you will have to 
**limit the choice**.

| Target                            | Mobile and Desktop | and JavaScript |
|----------------------------------|------------------|------------|
| Speed       | `Xorshift64`              | `Xorshift32`        |
| Quality     | `Xoshiro256pp`              | `Xoshiro128pp`        |

Full compatibility table:

| Class                            | Mobile and Desktop | JavaScript |
|----------------------------------|------------------|------------|
| **`Xorshift32`**      | **yes**              | **yes**        |
| **`Xorshift128`**                    | **yes**              | **yes**        |
| **`Xoshiro128pp`**                   | **yes**              | **yes**         |
| `Xorshift64`                     | yes              | no         |
| `Xorshift128p`                | yes              | no         |
| `Xoshiro256pp`                | yes              | no         |

# Classes

| Class             | Algorithm    | Algorithm author | Published |
|-------------------|--------------|------------------|------|
| `Xorshift32`      | [xorshift32](https://www.jstatsoft.org/article/view/v008i14)   | G. Marsaglia | 2003 |
| `Xorshift64`      | [xorshift64](https://www.jstatsoft.org/article/view/v008i14)   | G. Marsaglia | 2003 |
| `Xorshift128`     | [xorshift128](https://www.jstatsoft.org/article/view/v008i14)  | G. Marsaglia | 2003 |
| `Xorshift128p` | [xorshift128+](https://arxiv.org/abs/1404.0390) | S. Vigna | 2015 |
| `Xoshiro128pp` | [xoshiro128++ 1.0](https://prng.di.unimi.it/xoshiro128plusplus.c) | D. Blackman and S. Vigna | 2019 |
| `Xoshiro256pp` | [xoshiro256++ 1.0](https://prng.di.unimi.it/xoshiro256plusplus.c) | D. Blackman and S. Vigna | 2019 |

# Speed optimizations

### Raw bits

The `nextInt32()` and `nextInt64()` return the raw output of the generator. 

| Method | Returns | Equivalent of | 
|--------|---------|-----------|
| `nextInt32()` | 32-bit unsigned | `nextInt(0xFFFFFFFE)+1` |
| `nextInt64()` | 64-bit signed | `nextInt(0xFFFFFFFFFFFFFFFE)+1` |

| Time (lower is better) | nextInt | nextInt32 | nextInt64 |
|------------------------|---------|-----------|-----------|
| Random (dart:math)     |  1172   |     -     |     -     |
| Xorshift32             |   732   |    411    |     -     |
| Xorshift64             |  1046   |    776    |    746    |
| Xorshift128            |   886   |    606    |     -     |
| Xorshift128p           |  1081   |    802    |    857    |
| Xoshiro128pp           |  1203   |    902    |     -     |
| Xoshiro256pp           |  1691   |   1405    |   1890    |

### Rough double

`nextFloat`, unlike `nextDouble`, prefers speed to accuracy. It transforms 
a single 32-bit integer into a `double`. Therefore, the result is limited 
to a maximum of 2^32-1 values.

| Time (lower is better) | nextDouble | nextFloat |
|------------------------|------------|-----------|
| Random (dart:math)     |    1541    |     -     |
| Xorshift32             |    1122    |    405    |
| Xorshift64             |    994     |    777    |
| Xorshift128            |    1443    |    588    |
| Xorshift128p           |    1073    |    803    |
| Xoshiro128pp           |    2015    |    904    |
| Xoshiro256pp           |    2152    |   1386    |

# More benchmarks

| Time (lower is better) | nextInt | nextDouble | nextBool |
|------------------------|---------|------------|----------|
| Random (dart:math)     |  1172   |    1541    |   1134   |
| Xorshift32             |   732   |    1122    |   718    |
| Xorshift64             |  1046   |    994     |   703    |
| Xorshift128            |   886   |    1443    |   729    |
| Xorshift128p           |  1081   |    1073    |   715    |
| Xoshiro128pp           |  1203   |    2015    |   736    |
| Xoshiro256pp           |  1691   |    2152    |   744    |

All the benchmarks on this page are from AOT-compiled binaries running on AMD A9-9420e with Ubuntu 20.04. Time is measured in milliseconds.

# Consistency

The library has been thoroughly **tested to match reference numbers** generated by C algorithms. The
sources in C are taken directly from scientific publications or the reference implementations by the inventors of the algorithms. The Xorshift128+ results are also matched to reference
values from [JavaScript xorshift library](https://github.com/AndreasMadsen/xorshift), that tested
the 128+ similarly.

Testing is done in the GitHub Actions cloud on **Windows**, **Ubuntu** and **macOS** in **VM** and **Node.js** modes.

