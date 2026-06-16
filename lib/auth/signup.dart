import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/theme/app_theme.dart';
import './signverify.dart';
import 'package:intl/intl.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _termsAccepted = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedDate;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  Future<void> _registerUser() async {
    if (!_termsAccepted) {
      Fluttertoast.showToast(msg: "Please accept the terms and conditions");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _countryController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all required fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await SkyRideApi.instance.registerUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        dateOfBirth: _dobController.text,
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'user',
      );

      if (userId != null) {
        Fluttertoast.showToast(msg: "Account created successfully!");
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VerificationPage1()),
          );
        }
      } else {
        Fluttertoast.showToast(msg: "Email already registered");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = _dateFormat.format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Image.asset('assets/images/logo2.png', height: 160),
                  const SizedBox(height: 30),
                  _buildTextField(_usernameController, Icons.person, "Username"),
                  _buildTextField(_emailController, Icons.email, "Email"),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today),
                        labelText: "Date of Birth",
                      ),
                    ),
                  ),
                  _buildTextField(_countryController, Icons.location_on, "Country"),
                  _buildTextField(_phoneController, Icons.phone, "Phone"),
                  _buildPasswordField(_passwordController, "Password", true),
                  _buildPasswordField(_confirmPasswordController, "Confirm Password", false),
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                      ),
                      const Expanded(child: Text("I accept the Terms and Conditions")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sign Up", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Login here",
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_showPassword : !_showConfirmPassword,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock),
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(
              isPassword
                  ? (_showPassword ? Icons.visibility : Icons.visibility_off)
                  : (_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
            ),
            onPressed: () {
              setState(() {
                if (isPassword) {
                  _showPassword = !_showPassword;
                } else {
                  _showConfirmPassword = !_showConfirmPassword;
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
