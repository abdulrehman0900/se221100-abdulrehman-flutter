import '../models/user_model.dart';

class AuthController {
  static UserModel? user;

  static void register(UserModel u) {
    user = u;
  }

  static bool login(String email, String pass) {
    if (user == null) return false;
    return user!.email == email && user!.password == pass;
  }
}
