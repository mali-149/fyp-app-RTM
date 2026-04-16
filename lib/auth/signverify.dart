
import 'package:flutter/material.dart';
import 'login.dart';

class VerificationPage1 extends StatefulWidget {
  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage1> {
  final TextEditingController _codeController = TextEditingController();
  String verificationCode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo at the top
                    Image.asset(
                      'assets/images/logo.png', // Replace with your logo's path
                      height: 160,
                    ),
                    const SizedBox(height: 2),

                    const Text(
                      "Congratulations!🎉",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Your account has been successfully created! A link has been sent to your email 📩. Please check your inbox 📥 and click the link to activate your account ✅.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'Roboto', // Change to your preferred font
                      ),
                    ),


                    const SizedBox(height: 40),



                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          verificationCode = _codeController.text;
                        });
                        // Navigate to Reset Password Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Color(0xFFF25F12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Goto Login",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resend code link

                    const SizedBox(height: 20),

                    // Login Now Text Link with Underline

                  ],
                ),
              ),
            ),
          ),
          // Back Arrow Positioned at the top left corner
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Navigate back to ForgotPasswordPage
              },
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Color(0xFFF25F12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}