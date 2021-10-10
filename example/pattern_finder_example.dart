import 'dart:typed_data';
import 'package:pattern_finder/pattern_finder.dart';

/// Converts array from List<int> to Uint8List
Uint8List toUint8List(List<int> buf) {
  Uint8List data = new Uint8List(buf.length);
  for (int i = 0; i < data.length; i++) {
    data[i] = buf[i];
  }
  return data;
} // end function toUint8List

main() {
  /* Search for patterns using PatternFinder.Find and PatternFinder.Find_B functions */
  var pattern = PatternFinder.Transform('456?89?B');

  var buf1 = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF];
  var buf2 = [0x01, 0x23, 0x45, 0x66, 0x89, 0x6B, 0xCD, 0xEF];
  var buf3 = [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11];

  int foundOffset1 =
      PatternFinder.Find_B(toUint8List(buf1), 8, pattern); // foundOffset1: 2
  int foundOffset2 =
      PatternFinder.Find(toUint8List(buf2), 8, '456?89?B'); // foundOffset2: 2
  int foundOffset3 =
      PatternFinder.Find_B(toUint8List(buf3), 8, pattern); // foundOffset3: -1

  /* Search for patterns using signatures */
  var buf = [
    0x01,
    0x23,
    0x45,
    0x67,
    0x89,
    0xAB,
    0xCD,
    0xEF,
    0x45,
    0x65,
    0x67,
    0x89
  ];

  Signature sig1 = new Signature("pattern1", "456?89?B",
      func: (offset) => print('Found Pattern1!!! @ ${offset}'));
  Signature sig2 = new Signature("pattern2", "1111111111",
      func: () => print('Will I make it?'));
  Signature sig3 =
      new Signature("pattern3", "AB??EF", func: () => print('Found pattern3'));
  Signature sig4 = new Signature("pattern4", "45??67", func: (int offset) {
    // do something
    int new_offset = offset + 4;
    print('Found pattern4!!! Old Offset: ${offset}, New Offset: ${new_offset}');
  });
  List<Signature> signatures = [sig1, sig2, sig3, sig4];

  // Run `Scan` to execute founded signatures function
  SignatureFinder.Scan(toUint8List(buf), buf.length, signatures);

  //  Found Pattern1!!! @ 2
  //  Found pattern3
  //  Found pattern4!!! Old Offset: 8, New Offset: 12
}
