import '../utils/enums.dart';

class UserModel {
  final String name;
  final String email;
  final String password;
  final Gender gender;

  UserModel({
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
  });
}
