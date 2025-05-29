class Validators {
  static bool isValidEmail(String email) {
    final regex = RegExp(r"^[^@]+@[^@]+\.[^@]+$");
    return regex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
