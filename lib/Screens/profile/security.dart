import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(

        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            color: Color(0xFFF25F12),
            fontWeight: FontWeight.bold,
          ),

        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 20),
              Text(
                "Introduction",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25F12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Welcome to SkyRide. Your privacy is very important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our app for fuel delivery, car or bike mechanic assistance, and other roadside services.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                "Information We Collect",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25F12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "SkyRide may collect personal information such as your name, email address, phone number, location, and vehicle details. We also collect service request data and app usage information to enhance our services.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                "How We Use Your Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25F12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "1. To process your fuel delivery and mechanic requests.\n"
                    "2. To improve our service response and customer experience.\n"
                    "3. To communicate with you regarding updates or promotions.\n"
                    "4. To enhance safety and security.\n"
                    "5. To comply with legal obligations.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                "Location Data",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25F12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "SkyRide uses your real-time location to dispatch nearby service providers. Location access is essential for our app’s core functionality such as fuel or mechanic delivery.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                "Data Security",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25F12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We implement modern security practices to protect your data. However, no method of transmission over the internet or storage is 100% secure. We encourage responsible use of the app.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                "Changes to This Policy",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25F12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We may update this Privacy Policy periodically. We recommend reviewing this page regularly to stay informed about how your data is handled.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                "Contact Us",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF25F12),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "If you have any questions about this Privacy Policy, feel free to reach out to our support team at support@skyride.com.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
