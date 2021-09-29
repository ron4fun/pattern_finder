import 'package:pattern_finder/pattern_finder.dart';
import 'package:test/test.dart';
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

void main() {
    group('PatternFinder Tests', () {

        test('Find_Tests', () {
            var pattern = PatternFinder.Transform('456?89?B');

            var buf1 = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF];
            var buf2 = [0x01, 0x23, 0x45, 0x66, 0x89, 0x6B, 0xCD, 0xEF];
            var buf3 = [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11];

            int foundOffset1 = PatternFinder.Find_B(toUint8List(buf1), 8, pattern); // foundOffset1: 2
            int foundOffset2 = PatternFinder.Find(toUint8List(buf2), 8, '456?89?B'); // foundOffset2: 2
            int foundOffset3 = PatternFinder.Find_B(toUint8List(buf3), 8, pattern); // foundOffset3: -1

            expect(foundOffset1, 2);
            expect(foundOffset2, 2);
            expect(foundOffset3, -1);
        });

        test('Signature_Tests', () {
            Signature sig1 = new Signature("pattern1", "456?89?B");
            Signature sig2 = new Signature("pattern2", "1111111111");
            Signature sig3 = new Signature("pattern3", "AB??EF");
            Signature sig4 = new Signature("pattern4", "45??67");
            List<Signature> signatures = [sig1, sig2, sig3, sig4];

            var buf = [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0x45, 0x65, 0x67, 0x89];

            List<Signature> results = SignatureFinder.Scan(toUint8List(buf), buf.length, signatures);

            var offsets = [2, 5, 8];
            for (int i = 0; i < results.length; i++) {
                expect(results[i].FoundOffset, offsets[i]);
            }
        });
    });
}
