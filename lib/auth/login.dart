import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'signup.dart';
import 'forget.dart';
import '../navigation/navigation.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();



  // Future<void> _login() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   final String email = _emailController.text.trim();
  //   final String password = _passwordController.text.trim();
  //
  //   final url = Uri.parse('https://skyride.onrender.com/api/login');
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json', // Set content type to JSON
  //       },
  //       body: jsonEncode({
  //         'email': email,
  //         'password': password,
  //       }), // Encode body to JSON
  //     );
  //
  //     final responseData = jsonDecode(response.body);
  //     if (response.statusCode == 200 && responseData['message'] == "User login successful") {
  //       // Save token and user details to SharedPreferences
  //       final prefs = await SharedPreferences.getInstance();
  //       prefs.setString('token', responseData['token'] ?? '');
  //       prefs.setString('userId', responseData['user']['_id'] ?? '');
  //       prefs.setString('username', responseData['user']['username'] ?? '');
  //       prefs.setString('email', responseData['user']['email'] ?? '');
  //       prefs.setString('dob', responseData['user']['date_of_birth'] ?? '');
  //       prefs.setString('phone', responseData['user']['phone'].toString());
  //       prefs.setString('country', responseData['user']['country'] ?? '');
  //
  //       // Show success message
  //       Fluttertoast.showToast(
  //         msg: "Login successful!",
  //         toastLength: Toast.LENGTH_SHORT,
  //         gravity: ToastGravity.BOTTOM,
  //         backgroundColor: Colors.green,
  //         textColor: Colors.white,
  //       );
  //
  //       // Navigate after saving preferences
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => Navigationbar()),
  //       );
  //     } else {
  //       Fluttertoast.showToast(
  //         msg: responseData['message'] ?? "Login failed",
  //         toastLength: Toast.LENGTH_LONG,
  //         gravity: ToastGravity.BOTTOM,
  //         backgroundColor: Colors.red,
  //         textColor: Colors.white,
  //       );
  //     }
  //   } catch (error) {
  //     Fluttertoast.showToast(
  //       msg: "Something went wrong. Please try again.",
  //       toastLength: Toast.LENGTH_LONG,
  //       gravity: ToastGravity.BOTTOM,
  //       backgroundColor: Colors.red,
  //       textColor: Colors.white,
  //     );
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }



  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      // Simulate small delay like real login
      await Future.delayed(Duration(seconds: 1));

      // Save fake token + user details
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', 'fake_token_123456');
      prefs.setString('userId', 'fake_user_id_001');
      prefs.setString('username', 'Test User');
      prefs.setString('email', email);
      prefs.setString('dob', '2000-01-01');
      prefs.setString('phone', '0000000000');
      prefs.setString('country', 'Unknown');

      Fluttertoast.showToast(
        msg: "Login successful!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Navigationbar()),
      );

    } catch (error) {
      Fluttertoast.showToast(
        msg: "Something went wrong. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 160),
                Image.asset('assets/images/logo2.png', height: 160),
                const SizedBox(height: 60),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email or Username",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your email or username' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: !_isPasswordVisible,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                            );
                          },
                          child: const Text(
                            "Forgot?",
                            style: TextStyle(color: Color(0xFFF25F12), fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your password' : null,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: const Color(0xFFF25F12),
                  ),
                  child: const Text("Login", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an Account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                      },
                      child: const Text(
                        "Sign up here",
                        style: TextStyle(color: Color(0xFFF25F12), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
