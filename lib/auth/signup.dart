import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
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
        _confirmPasswordController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _countryController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all required fields");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var url = Uri.parse('https://skyride.onrender.com/api/signup');

    var request = http.MultipartRequest('POST', url);
    request.fields['username'] = _usernameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['password'] = _passwordController.text;
    request.fields['confirmpassword'] = _confirmPasswordController.text;
    request.fields['date_of_birth'] = _dobController.text;
    request.fields['country'] = _countryController.text;
    request.fields['phone'] = _phoneController.text;
    request.fields['role'] = 'user';

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        Fluttertoast.showToast(msg: data["message"]);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VerificationPage1()),
        );
      } else {
        Fluttertoast.showToast(msg: "Signup failed: ${response.reasonPhrase}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = _selectedDate ?? DateTime(2000);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
      backgroundColor: Colors.white,
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

                  // Date of Birth Picker Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today),
                        labelText: "Date of Birth",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      const Text("I accept the Terms and Conditions"),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFFF25F12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sign Up", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Login here", style: TextStyle(color: Color(0xFFF25F12), fontWeight: FontWeight.bold)),
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
                decoration: const BoxDecoration(color: Color(0xFFF25F12), shape: BoxShape.circle),
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
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: Icon(
              isPassword ? (_showPassword ? Icons.visibility : Icons.visibility_off)
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
