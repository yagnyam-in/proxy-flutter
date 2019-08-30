import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

class ConversionUtils {
  static T stringToEnum<T>(
    String value, {
    @required T orElse,
    @required List<T> values,
    @required String enumName,
  }) {
    return values.firstWhere(
      (e) => _isEnumEqual(e, value, enumName: enumName),
      orElse: () => orElse,
    );
  }

  static String enumToString<T>(
    T value, {
    @required String enumName,
  }) {
    return value?.toString()?.replaceFirst(enumName, "")?.toLowerCase();
  }

  static bool _isEnumEqual<T>(T enumValue, String stringValue, {String enumName}) {
    String asString = enumValue.toString().toLowerCase();
    return stringValue != null &&
        (asString == stringValue.toLowerCase() || asString == (enumName + "." + stringValue).toLowerCase());
  }

  static bool intToBool(int value) {
    if (value == null) {
      return null;
    } else {
      return value != 0;
    }
  }

  static int boolToInt(bool value) {
    if (value == null) {
      return null;
    } else if (value) {
      return 1;
    } else {
      return 0;
    }
  }

  static DateTime intToDateTime(int value) {
    if (value == null) {
      return null;
    } else {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }

  static int dateTimeToInt(DateTime value) {
    if (value == null) {
      return null;
    } else {
      return value.toUtc().millisecondsSinceEpoch;
    }
  }
}

String nullIfEmpty(String value) {
  return value == null || value.trim().isEmpty ? null : value;
}

