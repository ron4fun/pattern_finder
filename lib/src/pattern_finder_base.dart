/*
Copyright (c) 2021 Mbadiwe Nnaemeka Ronald ron2tele@gmail.com

    This software is provided 'as-is', without any express or implied
    warranty. In no event will the author be held liable for any damages
    arising from the use of this software.
    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation must be
    specified.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice must not be removed or altered from any source distribution.
*/

import 'dart:typed_data';

class _Nibble {
  int Data;
  bool Wildcard;
}

class _Byte {
  _Nibble N1 = new _Nibble();
  _Nibble N2 = new _Nibble();
  _Byte Clone() {
    _Byte copy = new _Byte();
    copy.N1.Wildcard = N1.Wildcard;
    copy.N1.Data = N1.Data;
    copy.N2.Wildcard = N2.Wildcard;
    copy.N2.Data = N2.Data;
    return copy;
  }
}

/// It handles how patterns are found in the byte streams.
class PatternFinder {
  static String _Format(String data) {
    String tempRes = '';
    for (int i = 0; i < data.length; i++) {
      int ch = data.codeUnitAt(i);
      if ((ch >= 48 && ch <= 57) ||
          (ch >= 65 && ch <= 90) ||
          (ch >= 97 && ch <= 122) ||
          (ch == 63)) {
        tempRes = tempRes + data[i];
      }
    } // end for

    return tempRes;
  } // end class Format

  static List<_Byte> Transform(String data) {
    String pattern = PatternFinder._Format(data);
    int length = pattern.length;

    if (length == 0) return [];

    List<_Byte> tempRes = [];

    if (length % 2 != 0) {
      pattern = pattern + '?';
      length++;
    } // end if

    int j = 0, a = 0x2;
    _Byte new_byte = new _Byte();
    for (int i = 0; i < length; i++) {
      String ch = pattern[i];

      if (ch == '?') // wildcard
      {
        if (j == 0) {
          new_byte.N1.Wildcard = true;
        } else {
          new_byte.N2.Wildcard = true;
        }
      } else {
        if (j == 0) {
          new_byte.N1.Wildcard = false;
          new_byte.N1.Data =
              (PatternFinder._HexChToInt(ch.codeUnitAt(0)) & 0xF);
        } // end if
        else {
          new_byte.N2.Wildcard = false;
          new_byte.N2.Data =
              (PatternFinder._HexChToInt(ch.codeUnitAt(0)) & 0xF);
        } // end else
      } // end else

      j++;
      if (j == 2) {
        j = 0;
        tempRes.add(new_byte.Clone());
      } // end if
    } // end for

    return tempRes;
  } // end class Transform

  /// Returns the offset of the found pattern else -1
  ///
  /// ```dart
  /// var offset = PatternFinder.Find_B(buffer, 8, pattern); // offset: 2
  ///
  static int Find_B(List<int> data, int length, List<_Byte> pattern) {
    int offsetFound = -1;

    if (data == null || pattern.isEmpty) return offsetFound;

    int patternSize = pattern.length;
    if (length == 0 || patternSize == 0) return offsetFound;

    int i = 0, pos = 0;
    while (i < length) {
      if (PatternFinder._MatchByte(data.elementAt(i), pattern[pos])) {
        // check if the current data byte matches the current pattern byte
        pos++;
        if (pos == patternSize) // everything matched
        {
          offsetFound = i - patternSize + 1;
          return offsetFound;
        } // end if
      } // end if
      else // fix by Computer_Angel
      {
        i -= pos;
        pos = 0; // reset current pattern position
      } // end else

      i++;
    } // end while

    return offsetFound;
  }

  /// Returns the offset of the found pattern else -1
  ///
  /// ```dart
  /// var offset = PatternFinder.Find(buffer, 8, pattern); // offset: 2
  /// ```
  static int Find(List<int> data, int length, String pattern) =>
      Find_B(data, length, PatternFinder.Transform(pattern));

  static int _HexChToInt(int ch) {
    if (ch >= 48 && ch <= 57) {
      return ch - 48;
    } else if (ch >= 65 && ch <= 90) {
      return ch - 65 + 10;
    } else if (ch >= 97 && ch <= 122) {
      return ch - 97 + 10;
    }
    return -1;
  } // end function hexChToInt

  static bool _MatchByte(int b, _Byte p) {
    int N1, N2;

    if (!p.N1.Wildcard) // if not a wildcard we need to compare the data.
    {
      N1 = b >> 4;
      if (N1 != p.N1.Data) // if the data is not equal b doesn't match p.
      {
        return false;
      }
    } // end if

    if (!p.N2.Wildcard) // if not a wildcard we need to compare the data.
    {
      N2 = b & 0xF;
      if (N2 != p.N2.Data) // if the data is not equal b doesn't match p.
      {
        return false;
      }
    } // end if

    return true;
  } // end function matchByte

} // end class PatternFinder

/// It is a representation of wildcard search pattern with signature name with which to identify them later.
/// In addition you can pass an anonymous function that will be called once pattern is found.
///
/// ```dart
/// Signature sig3 = new Signature("pattern3", "AB??EF", func: () => print('Found pattern3'));
/// ```
class Signature {
  String _Name;
  List<_Byte> _Pattern;
  int _FoundOffset;
  var _Func;

  Signature(String name, String pattern, {func = null}) {
    _Name = name;
    _Pattern = PatternFinder.Transform(pattern);
    _Func = func;
  } // end constructor

  @override
  String toString() => Name;

  String get Name => _Name;

  List<_Byte> get Pattern => _Pattern;

  int get FoundOffset => _FoundOffset;

  // execute function
  get ExecFunc => _Func;

  set FoundOffset(int value) => _FoundOffset = value;
} // end class Signature

/// It handles the signature pattern searches.
///
/// ```dart
/// SignatureFinder.Scan(buffer, buffer.length, signatures);
/// ```
class SignatureFinder {
  /// Returns a list of found signatures.
  ///
  /// ```dart
  /// var results = SignatureFinder.Scan(buffer, buffer.length, signatures);
  /// ```
  static List<Signature> Scan(
      List<int> data, int length, List<Signature> signatures) {
    int tempOffset;

    List<Signature> found = [];
    List<Signature> sigs = new List<Signature>.from(signatures);

    for (int i = 0; i < sigs.length; i++) {
      tempOffset = PatternFinder.Find_B(data, length, sigs[i].Pattern);
      if (tempOffset != -1) {
        sigs[i].FoundOffset = tempOffset;
        if (sigs[i].ExecFunc != null) {
          try {
            sigs[i].ExecFunc(tempOffset);
          } on NoSuchMethodError {
            sigs[i].ExecFunc();
          } catch (e) {
            throw new Exception('Incorrectly formed signature function');
          }
        }
        // add to found signatures array
        found.add(sigs[i]);
      } // end if
    } // end for

    return found;
  } // end function Scan

} // end class SignatureFinder
