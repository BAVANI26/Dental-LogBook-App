import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final collegeController = TextEditingController();
  final departmentController = TextEditingController();
  final rollController = TextEditingController();
  final passwordController = TextEditingController();
  final facultyIdController = TextEditingController();
  String? selectedRole;
  bool isLoading = false;
  bool _obscurePassword = true;

  // ─── Show error snackbar ──────────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Password strength validation (REG-05) ───────────────────
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number (0-9).';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character (!@#\$%).';
    }
    return null;
  }

  // ─── Email format validation (REG-04) ────────────────────────
  String? _validateEmail(String email) {
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address (e.g. name@example.com).';
    }
    return null;
  }

  void register() async {
    if (selectedRole == null) {
      _showError('Please select Student or Faculty role!');
      return;
    }
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (emailController.text.trim().isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    // REG-04: Email format check
    final emailError = _validateEmail(emailController.text.trim());
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      _showError('Please enter a password.');
      return;
    }

    // REG-05: Password strength check
    final passwordError = _validatePassword(passwordController.text.trim());
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    if (selectedRole == 'faculty' && facultyIdController.text.trim().isEmpty) {
      _showError('Please enter your Faculty ID.');
      return;
    }

    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'college': collegeController.text.trim(),
        'department': departmentController.text.trim(),
        'rollNumber': selectedRole == 'student' ? rollController.text.trim() : '',
        'facultyId': selectedRole == 'faculty' ? facultyIdController.text.trim() : '',
        'role': selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showSuccess('Account created successfully! Please login. ✅');
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered. Please login instead.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address (e.g. name@example.com).';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 8 characters with uppercase, number, and special character.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed. Please try again.';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }
    setState(() => isLoading = false);
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8899BB)),
        prefixIcon: Icon(icon, color: const Color(0xFFC9A84C)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF8899BB),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3F60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC9A84C), width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFF0A1628),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2040),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC9A84C), width: 1),
                  boxShadow: [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.15), blurRadius: 30, spreadRadius: 2)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC9A84C), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(text: 'Logo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                        TextSpan(text: 'Dent', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFC9A84C))),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    const Text('Create Account', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 4),
                    const Text('Select your role to continue', style: TextStyle(fontSize: 13, color: Color(0xFF8899BB))),
                    const SizedBox(height: 28),

                    // Role selector
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedRole = 'student'),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: selectedRole == 'student' ? const Color(0xFFC9A84C) : const Color(0xFF0A1628),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC9A84C), width: 1.5),
                              ),
                              child: Center(
                                child: Text('🎓 Student',
                                    style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold,
                                      color: selectedRole == 'student' ? const Color(0xFF0A1628) : const Color(0xFFC9A84C),
                                    )),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedRole = 'faculty'),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: selectedRole == 'faculty' ? const Color(0xFFC9A84C) : const Color(0xFF0A1628),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC9A84C), width: 1.5),
                              ),
                              child: Center(
                                child: Text('👨‍⚕️ Faculty',
                                    style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold,
                                      color: selectedRole == 'faculty' ? const Color(0xFF0A1628) : const Color(0xFFC9A84C),
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (selectedRole != null) ...[
                      _buildField(nameController, 'Full Name', Icons.person_outlined),
                      const SizedBox(height: 14),
                      _buildField(emailController, 'Email', Icons.email_outlined),
                      const SizedBox(height: 14),
                      _buildField(collegeController, 'College Name', Icons.account_balance_outlined),
                      const SizedBox(height: 14),
                      _buildField(departmentController, 'Department', Icons.local_hospital_outlined),
                      const SizedBox(height: 14),
                      if (selectedRole == 'student') ...[
                        _buildField(rollController, 'Roll Number', Icons.badge_outlined),
                        const SizedBox(height: 14),
                      ],
                      if (selectedRole == 'faculty') ...[
                        _buildField(facultyIdController, 'Faculty ID', Icons.badge_outlined),
                        const SizedBox(height: 6),
                        const Text('Students will use this ID to submit cases',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                        const SizedBox(height: 14),
                      ],

                      // Password field with show/hide + strength hint
                      _buildField(passwordController, 'Password', Icons.lock_outlined, isPassword: true),
                      const SizedBox(height: 6),
                      // REG-05: Password rules hint
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1628),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A3F60)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Password must contain:', style: TextStyle(fontSize: 11, color: Color(0xFF8899BB), fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('• At least 8 characters', style: TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                            Text('• One uppercase letter (A-Z)', style: TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                            Text('• One number (0-9)', style: TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                            Text('• One special character (!@#\$%)', style: TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC9A84C),
                            foregroundColor: const Color(0xFF0A1628),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Color(0xFF0A1628))
                              : const Text('Register', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: Color(0xFF8899BB))),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Login', style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}