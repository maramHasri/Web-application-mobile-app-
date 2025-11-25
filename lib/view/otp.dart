import 'package:flutter/material.dart';
import 'package:flutter_internet_application/service/register.dart';

class OtpVerify extends StatefulWidget {
  final String identifier; // الإيميل أو رقم الهاتف المستخدم عند التسجيل

  const OtpVerify({super.key, required this.identifier});

  @override
  State<OtpVerify> createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthServiceImpl();

  bool _isLoading = false;

  void _verifyCode() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى إدخال رمز التحقق")));
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _authService.verifyOtp(
      widget.identifier, // نفس الإيميل / الرقم الذي سجل به
      _otpController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessPage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("رمز التحقق غير صحيح")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد رمز الـ OTP"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "تم إرسال رمز التحقق إلى:\n${widget.identifier}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: "أدخل رمز الـ OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "تأكيد",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة نجاح بسيطة
class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("نجاح التحقق")),
      body: const Center(
        child: Text(
          "🎉 تم التحقق بنجاح!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
