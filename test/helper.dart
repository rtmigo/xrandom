// SPDX-FileCopyrightText: (c) 2021 Art Galkin <github.com/rtmigo>
// SPDX-License-Identifier: BSD-3-Clause


import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

import 'package:test/test.dart';
import 'package:xrandom/src/10_random_base.dart';
import 'package:quiver/iterables.dart';

//import 'package:xrandom/src/10_random_base.dart';
import 'package:xrandom/src/10_random_base.dart';
import 'package:xrandom/src/00_ints.dart';

//import '../labuda/2021-03-15/reference.dart.txt';

import 'data/generated.dart';

// File fileInData(String localName) {
//   return File(path.join(Directory.current.path, "test/data/" + localName));
// }

enum ReferenceType {
  ints,
  double_mult,
  double_cast
}

// main() {
//   for (var m in referenceData)
//     print(m['seed id']);
// }

// File dataFile(String algo, String seedId, ReferenceType type) {
//   String suffix;
//   switch (type) {
//     case ReferenceType.ints:
//       suffix = 'int';
//       break;
//     case ReferenceType.double_mult:
//       suffix = 'double_mult';
//       break;
//     case ReferenceType.double_cast:
//       suffix = 'double_cast';
//       break;
//   }
//   return fileInData('${algo}_${seedId}_$suffix.txt');
// }

Map dataMap(String algo, String seedId, ReferenceType type) {
  String suffix;
  switch (type) {
    case ReferenceType.ints:
      suffix = 'int';
      break;
    case ReferenceType.double_mult:
      suffix = 'double_mult';
      break;
    case ReferenceType.double_cast:
      suffix = 'double_cast';
      break;
  }

  for (final m in referenceData)
    {
      if (m['algorithm']==algo && m['seed id']==seedId && m['type']==suffix) {
        return m;
      }
    }
  throw Exception('Not found [$algo] [$seedId] [$suffix]');

//  return fileInData('${algo}_${seedId}_$suffix.txt');
}



// Iterable<double> loadDoubles(File file) sync* {
//   for (var line in file.readAsLinesSync()) {
//     if (line.trimLeft().startsWith('#') || line
//         .trim()
//         .isEmpty) {
//       continue;
//     }
//     yield double.parse(line);
//   }
// }



Iterable<double> loadDoubles(Map m) sync* {
  for (var line in m['values']) {
    // if (line.trimLeft().startsWith('#') || line.trim().isEmpty) {
    //   continue;
    // }
    yield double.parse(line);
  }
}

Iterable<String> rdIntsAsStrings(Map m) {
  return m['values'];
  // for (var line in m['values']) {
  //   // if (line.trimLeft().startsWith('#') || line.trim().isEmpty) {
  //   //   continue;
  //   // }
  //   return
  //   //yield BigInt.parse(line, radix: 16).toInt();
  // }
}

class Enumerated<T> {
  Enumerated(this.index, this.value);
  late int index;
  late T value;
}

// Iterable<Enumerated<T>> enumerate<T>(Iterable<T> data) sync*
// {
//   late Enumerated<T> retval;
//   int i=0;
//   for (final t in data) {
//     if (i == 0) {
//       retval = Enumerated<T>(0, t);
//     }
//     else {
//       retval.index = 0;
//       retval.value = t;
//     }
//     yield retval;
//     i++;
//   }
// }
/*
extension Itertools<T> on Iterable<T> {


}*/


void checkReferenceFiles(RandomBase32 Function() createRandom, String seedId) {

  group('Reference data ${createRandom().runtimeType} seedId=$seedId', () {

    late RandomBase32 random;
    late String filePrefix;

    setUp(() {
      random = createRandom();
      filePrefix = random.runtimeType.toString().toLowerCase();
    });

    test('toDouble', () {

      final reftype = (random is RandomBase64) ? ReferenceType.double_mult : ReferenceType.double_cast;

      //if (random is RandomBase64)

      final values = loadDoubles(dataMap(filePrefix, seedId, reftype));
      int idx = 0;
      for (final value in values) {
        expect(random.nextDouble(), value, reason: 'item ${idx++}');
      }
    });

    if (createRandom() is RandomBase64) {
      test('nextDoubleMemcast', () {
        final values = loadDoubles(dataMap(filePrefix, seedId, ReferenceType.double_cast));
        int idx = 0;
        for (final value in values) {
          expect((random as RandomBase64).nextDoubleMemcast(), value, reason: 'item ${idx++}');
        }
      });
    }
    //final a = 0xfd7345d28bddd768;

    if (createRandom() is RandomBase64) {
      test('nextInt64', () {
        final values = rdIntsAsStrings(dataMap(filePrefix, seedId, ReferenceType.ints));
        //int idx = 0;
        for (final item in enumerate(values)) {
          expect((random as RandomBase64).nextInt64().toHexUint64uc().toLowerCase(), item.value, reason: 'item ${item.index}');
        }
      });
    } else {
      test('nextInt32', () {
        // final values = loadInts(dataMap(filePrefix, seedId, ReferenceType.ints));
        // //int idx = 0;
        // for (final item in enumerate(values)) {
        //   expect(random.nextInt32(), item.value, reason: 'item ${item.index}');
        // }
      });
    }


    // test('double memory cast', () {
    //   compareDoubles(
    //       createRandom(), loadDoubles(refFile("xorshift64", seedId, ReferenceType.double_cast)));
    // });

  });
}

List expectedList(RandomBase32 r) => [(r is RandomBase64) ? r.nextInt64() : r.nextInt32(), r.nextInt(100000), r.nextDouble(), r.nextBool(), r.nextBool(), r.nextBool()];


void compareDoubles(RandomBase64 random, Iterable<double> values) {
  int idx = 0;
  for (final value in values) {
    expect(random.nextDouble(), value, reason: 'item ${idx++}');
  }
}

String trimLeadingZeros(String s) {
  return s.replaceAll(new RegExp(r'^0+(?=.)'), '');
}

// void compareWithReference32(RandomBase32 random, referenceKey) {
//   final refList = referenceData[referenceKey]!;
//   for (final value in refList) {
//     final x = random.nextInt32();
//     expect(trimLeadingZeros(x.toHexUint64()), trimLeadingZeros(value.toUpperCase()));
//   }
// }
//
// void compareWithReference64(RandomBase64 random, referenceKey) {
//   final refList = referenceData[referenceKey]!;
//   for (final value in refList) {
//     final x = random.nextInt64();
//     expect(trimLeadingZeros(x.toHexUint64()), trimLeadingZeros(value.toUpperCase()));
//   }
// }


// /// We just take a big list from our reference data, and return
// /// a few values from it.
// ///
// /// Reference data in "always ok" except if we messed up data on update.
// /// This signature helps to make sure, that the reference is ok
// List<String> referenceSignature(String referenceKey) {
//   List<String> list = referenceData[referenceKey]!;
//   return [list[0], list[1], list[2], list[500]];
// }


void testCommonRandom(Random Function() createRandom) {
  group('Common random ${createRandom().runtimeType}', () {
    test('doubles', () => checkDoubles(createRandom()));
    test('bools', () => checkBools(createRandom()));
    test('ints', () => checkInts(createRandom()));

    test('Seed is different each time', () {
      // even with different seeds, we can get rare matches of results.
      // But most of the the results should be unique
      expect(
          List
              .generate(100, (index) => createRandom().nextDouble())
              .toSet()
              .length,
          greaterThan(90));
    });

    test('Huge ints: 0xFFFFFFFF', ()=>checkHugeInts(createRandom(), 0xFFFFFFFF));
    // "the fast case for powers of two"
    test('Huge ints: 0x80000000', ()=>checkHugeInts(createRandom(), 0x80000000));

    test('nextIntCheckRange', () {
      final r = createRandom();
      expect(()=>r.nextInt(-1), throwsRangeError);
      expect(()=>r.nextInt(0), throwsRangeError);
      expect(()=>r.nextInt(0xFFFFFFFF+1), throwsRangeError);
      // no errors
      r.nextInt(1);
      r.nextInt(0xFFFFFFFF);
    });

    //test("Huge int32")
  });
}


void checkDoubles(Random r) {
  int countSmall = 0;
  int countBig = 0;
  int countMiddle = 0;

  const N = 10000000;
  for (int i = 0; i < N; ++i) {
    var d = r.nextDouble();
    expect(d, greaterThanOrEqualTo(0.0));
    expect(d, lessThan(1.0));

    if (d > 0.99)
      countBig++;
    else if (d < 0.01)
      countSmall++;
    else if (d >= 0.495 && d < 0.505)
      countMiddle++;
  }

  expect(countBig, greaterThan(N / 1000));
  expect(countSmall, greaterThan(N / 1000));
  expect(countMiddle, greaterThan(N / 1000));
}

void checkBools(Random r) {
  int countTrue = 0;

  const N = 10000000;
  for (int i = 0; i < N; ++i) {
    if (r.nextBool())
      countTrue++;
  }

  expect(countTrue, greaterThan(N * 0.4));
  expect(countTrue, lessThan(N * 0.6));
}

void checkInts(Random r) {

  int countMin = 0;
  int countMax = 0;
  const N = 10000000;

  for (int i = 0; i < N; ++i) {
    var x = r.nextInt(10);
    expect(x, greaterThanOrEqualTo(0));
    expect(x, lessThan(10));
    if (x == 0) {
      countMin++;
    } else if (x == 9) {
      countMax++;
    }
  }

  expect(countMin, greaterThan(N * 0.08));
  expect(countMin, lessThan(N * 0.12));

  expect(countMax, greaterThan(N * 0.08));
  expect(countMax, lessThan(N * 0.12));
}

void checkHugeInts(Random r, final int upper) {

  // check that when we choose a large value of upper,
  // - we're never cross the margins
  // - we're are getting values close the margin

  int countAlmostTop = 0;
  const N = 10000000;

  for (int i = 0; i < N; ++i) {
    var x = r.nextInt(upper);
    expect(x, greaterThanOrEqualTo(0));
    expect(x, lessThan(upper));
    if (x >= upper*0.9) {
      countAlmostTop++;
    }
  }

  expect(countAlmostTop, greaterThan(N * 0.05));
}


List<T> skipAndTake<T>(T func(), int skip, int take) {
  for (var i = 0; i < skip; ++i)
    func();

  final result = <T>[];
  for (var i = 0; i < take; ++i)
    result.add(func());

  assert(result.length == take);
  return result;
}

String unsignedRightShiftCode(String x, String shift) {
  return '(// ($x) >>> ($shift)\n'
      '($x) >> ($shift)) & ~(-1 << (64 - ($shift)) )';
}
