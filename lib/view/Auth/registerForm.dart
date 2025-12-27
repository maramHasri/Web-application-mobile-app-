import 'package:flutter/material.dart';
import 'package:flutter_internet_application/core/widget/app_button.dart';
import 'package:flutter_internet_application/core/widget/app_textfield.dart';
import 'package:flutter_internet_application/model/userModel.dart';
import 'package:flutter_internet_application/service/register.dart';
import 'package:flutter_internet_application/view/otp.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  String errorMessage = "";
  String successMessage = "";

  AuthServiceImpl auth = AuthServiceImpl();

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = "";
      successMessage = "";
    });

    User user = User(
      name: nameController.text.trim(),
      identifier: identifierController.text.trim(),
      national_id: nationalIdController.text.trim(),
      password: passwordController.text.trim(),
      role_id: 3,
    );

    final result = await auth.register(user);

    setState(() => isLoading = false);

    if (result["success"] == true) {
      successMessage = "تم إنشاء الحساب بنجاح 🎉";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerify(identifier: user.identifier),
        ),
      );
    } else {
      if (result["errors"] != null && result["errors"].isNotEmpty) {
        errorMessage = result["errors"].values.first[0].toString();
      } else {
        errorMessage = result["message"] ?? "حدث خطأ";
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text("إنشاء حساب"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                AppTextField(
                  labelText: "الاسم",
                  // hintText: "أدخل اسمك الكامل",
                  controller: nameController,
                  myIcon: const Icon(Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "الرجاء إدخال الاسم";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  labelText: "الرقم الوطني",
                  // hintText: "أدخل الرقم الوطني",
                  controller: nationalIdController,
                  myIcon: const Icon(Icons.badge),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "الرجاء إدخال الرقم الوطني";
                    }
                    if (value.length != 11) {
                      return "الرقم الوطني يجب أن يكون 11 رقم";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  labelText: "البريد الإلكتروني أو الهاتف",
                  // hintText: "أدخل البريد أو الهاتف",
                  controller: identifierController,
                  myIcon: const Icon(Icons.mail),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "الرجاء إدخال البريد أو الهاتف";
                    }

                    if (value.startsWith("963")) return null;

                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                    );

                    if (!emailRegex.hasMatch(value)) {
                      return "أدخل رقم هاتف يبدأ بـ 963 أو بريد صحيح";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  labelText: "كلمة المرور",
                  // hintText: "أدخل كلمة المرور",
                  controller: passwordController,
                  obscureText: obscurePassword,
                  myIcon: const Icon(Icons.lock),
                  traillingIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "الرجاء إدخال كلمة المرور";
                    }
                    if (value.length < 6) {
                      return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  labelText: "تأكيد كلمة المرور",
                  // hintText: "أعد إدخال كلمة المرور",
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  myIcon: const Icon(Icons.lock),
                  traillingIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "الرجاء تأكيد كلمة المرور";
                    }
                    if (value != passwordController.text) {
                      return "كلمة المرور غير متطابقة";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (successMessage.isNotEmpty)
                  Text(
                    successMessage,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.greenAccent
                          : Colors.green,
                    ),
                  ),

                const SizedBox(height: 15),

                isLoading
                    ? const CircularProgressIndicator()
                    : AppButton(
                        text: "إنشاء الحساب",
                        width: double.infinity,
                        height: 50,
                        onTap: register,
                      ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
