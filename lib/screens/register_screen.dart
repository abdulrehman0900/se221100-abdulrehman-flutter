import 'package:flutter/material.dart';
import '../utils/validator.dart';
import '../utils/enums.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String pass = '';
  String confirm = '';
  Gender gender = Gender.male;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Join the student portal",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                ),
                const SizedBox(height: 32),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _field(
                        "Full Name",
                        Icons.person,
                        (v) => name = v,
                        (v) => Validator.name(v!),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        "Email Address",
                        Icons.email,
                        (v) => email = v,
                        (v) => Validator.email(v!),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        obscureText: _obscurePass,
                        onChanged: (v) => pass = v,
                        validator: (v) => Validator.password(v!),
                        style: const TextStyle(color: Color(0xFFF8FAFC)),
                        decoration: _dec("Password", Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        obscureText: _obscureConfirm,
                        onChanged: (v) => confirm = v,
                        validator: (v) => Validator.confirm(v!, pass),
                        style: const TextStyle(color: Color(0xFFF8FAFC)),
                        decoration: _dec("Confirm Password", Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<Gender>(
                        initialValue: gender,
                        dropdownColor: const Color(0xFF1E293B),
                        iconEnabledColor: const Color(0xFF64748B),
                        style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 15),
                        decoration: _dec("Gender", Icons.wc),
                        items: Gender.values.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g.name));
                        }).toList(),
                        onChanged: (v) => gender = v!,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              AuthController.register(
                                UserModel(
                                  name: name,
                                  email: email,
                                  password: pass,
                                  gender: gender,
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            }
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    IconData icon,
    Function(String) onChange,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      onChanged: onChange,
      validator: validator,
      style: const TextStyle(color: Color(0xFFF8FAFC)),
      decoration: _dec(label, icon),
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      errorStyle: const TextStyle(color: Color(0xFFEF4444)),
    );
  }
}
