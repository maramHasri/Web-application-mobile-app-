import 'package:flutter/material.dart';
import 'view/signUp.dart'; // مسار الشاشة التي أنشأتها

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:  SignUpOrEnterAsGuest(),
    );
  }
}
