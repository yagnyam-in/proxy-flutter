
class ConversionUtils {

  static bool isEnumEqual<T>(T enumValue, String stringValue, {String enumName}) {
    String asString = enumValue.toString().toLowerCase();
    return stringValue != null &&
        (asString == stringValue.toLowerCase() || asString == (enumName + "." + stringValue).toLowerCase());
  }

}