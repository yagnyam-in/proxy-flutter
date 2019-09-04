import 'package:quiver/strings.dart';

bool isPhoneNumber(String input) {
  if (isEmpty(input)) {
    return false;
  }
  if (input[0] != '+') {
    return false;
  }
  return true;
}

bool isEmailAddress(String input) {
  if (isEmpty(input)) {
    return false;
  }
  if (!input.contains('@')) {
    return false;
  }
  return true;
}
