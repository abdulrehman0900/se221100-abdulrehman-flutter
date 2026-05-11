class Validator {
  static String? name(String value) {
    if (value.isEmpty) return 'Required';
    return null;
  }

  static String? email(String value) {
    if (!value.contains('@')) return 'Invalid email';
    return null;
  }

  static String? password(String value) {
    if (value.length < 6) return 'Min 6 chars';
    if (!value.contains(RegExp(r'[A-Z]'))) return '1 uppercase required';
    if (!value.contains(RegExp(r'[!@#\$%^&*]'))) return '1 special required';
    return null;
  }

  static String? confirm(String value, String pass) {
    if (value != pass) return 'Not match';
    return null;
  }
}
