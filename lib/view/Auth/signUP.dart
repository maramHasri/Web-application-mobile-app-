import 'package:flutter/material.dart';
import 'package:flutter_internet_application/core/widget/app_button.dart';

import 'package:flutter_internet_application/view/login.dart';
import 'package:flutter_internet_application/view/Auth/registerForm.dart';

class SignUpOrEnterAsGuest extends StatelessWidget {
  const SignUpOrEnterAsGuest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/Isolation_Mode.png',
                  width: 180,
                  height: 200,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 20),

                Text(
                  "خدمة المواطن",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 50),

                AppButton(
                  text: "إنشاء حساب",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  width: double.infinity,
                  height: 50,
                ),

                const SizedBox(height: 16),

                AppButton(
                  text: "تسجيل الدخول",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  width: double.infinity,
                  height: 50,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
