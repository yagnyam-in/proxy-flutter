bool isPhoneNumber(String input) {
  if (input.isEmpty) {
    return false;
  }
  if (input[0] != '+') {
    return false;
  }
  return true;
}

bool isEmailAddress(String input) {
  if (input.isEmpty) {
    return false;
  }
  if (!input.contains('@')) {
    return false;
  }
  return true;
}
