import 'package:flutter/material.dart';
import 'package:flutter_internet_application/model/userModel.dart';
import 'package:flutter_internet_application/service/register.dart';
import 'package:flutter_internet_application/view/otp.dart'; // ملف السيرفس

class RegisterForm extends StatefulWidget {
  RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final contactController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _authService = AuthServiceImpl();
  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    User user = User(
      name: nameController.text.trim(),
      national_id: nationalIdController.text.trim(),
      identifier: contactController.text.trim(),
      password: passwordController.text.trim(),
      role_id: 3,
    );

    var result = await _authService.register(user);

    setState(() {
      _isLoading = false;
    });

    print("REGISTER RESULT: $result");

    // إذا رجع identifier موجود، ننتقل لصفحة OTP
    if (result["identifier"] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerify(identifier: result["identifier"]),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerify(identifier: result["identifier"]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إنشاء حساب"), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "الاسم الكامل",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "الرجاء إدخال الاسم";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nationalIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "الرقم الوطني",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                // validator: (value) {
                //   if (value == null || value.length != 11) {
                //     return "الرقم الوطني يجب أن يكون 11 خانات";
                //   }
                //   return null;
                // },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: "الإيميل أو رقم الموبايل",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "الرجاء إدخال الإيميل أو رقم الموبايل";
                  }
                  final input = value.trim();
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

                  if (emailRegex.hasMatch(input)) {
                    return null;
                  }
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "كلمة السر",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "كلمة السر يجب أن تكون 6 محارف على الأقل";
                  }
                  return null;
                },
              ),
              SizedBox(height: 50),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "إنشاء الحساب",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// واجهة تجريبية بعد التسجيل
class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("الصفحة الرئيسية")),
      body: Center(child: Text("تم تسجيل الدخول بنجاح!")),
    );
  }
}
