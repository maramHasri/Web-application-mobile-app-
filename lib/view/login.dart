import 'package:flutter/material.dart';
import 'package:flutter_internet_application/l10n/app_localizations.dart';
import 'package:flutter_internet_application/service/login.dart';
import 'package:flutter_internet_application/service/fcm_token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_internet_application/view/complain.dart';
import 'package:flutter_internet_application/core/widget/app_textfield.dart';
import 'package:flutter_internet_application/core/widget/app_button.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  String errorMessage = "";
  String successMessage = "";

  final storage = const FlutterSecureStorage();
  final LoginService loginService = LoginService();
  final FcmTokenService fcmTokenService = FcmTokenService();

  Future<String> getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("Obtained Device Token: $token");
    return token ?? "";
  }

  bool containsArabicCharacters(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  bool isPhoneNumber(String identifier) {
    final phoneRegex = RegExp(r'^[0-9]+$');
    return phoneRegex.hasMatch(identifier);
  }

  String? validateIdentifier(String? value) {
    if (value == null || value.isEmpty) {
      return "الرجاء إدخال رقم الهاتف أو البريد الإلكتروني";
    }
    final trimmedValue = value.trim();
    if (containsArabicCharacters(trimmedValue)) {
      return "يجب إدخال رقم الهاتف بالأرقام الإنجليزية فقط";
    }
    if (isPhoneNumber(trimmedValue)) {
      if (!trimmedValue.startsWith("963")) {
        return "يجب أن يبدأ رقم الهاتف بـ 963";
      }
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
      if (!emailRegex.hasMatch(trimmedValue)) {
        return "أدخل رقم هاتف يبدأ بـ 963 أو بريد إلكتروني صحيح";
      }
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "الرجاء إدخال كلمة المرور";
    }
    if (value.length < 8) {
      return "كلمة المرور يجب أن تكون 8 أحرف على الأقل";
    }
    return null;
  }

  Future<void> login() async {
    final identifierError = validateIdentifier(identifierController.text);
    final passwordError = validatePassword(passwordController.text);
    if (identifierError != null || passwordError != null) {
      setState(() {
        errorMessage = identifierError ?? passwordError ?? "";
        successMessage = "";
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = "";
      successMessage = "";
    });
    try {
      final deviceToken = await getDeviceToken();
      final result = await loginService.login(
        identifier: identifierController.text.trim(),
        password: passwordController.text.trim(),
        deviceToken: deviceToken,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (result["success"] == true) {
          successMessage = result["message"] ?? "تم تسجيل الدخول بنجاح 🎉";
        } else {
          errorMessage = result["message"] ?? "حدث خطأ غير متوقع";
        }
      });

      if (result["success"] == true) {
        String userToken = result["data"]["token"] ?? "";
        if (userToken.isEmpty) {
          setState(() {
            isLoading = false;
            errorMessage = "فشل الحصول على رمز المصادقة";
          });
          return;
        }

        await storage.write(key: "userToken", value: userToken);
        debugPrint("✅ User token saved to secure storage");

        // Send FCM token to backend after successful login
        final bool tokenSent = await fcmTokenService.sendTokenToBackend(
          userToken,
        );
        if (tokenSent) {
          debugPrint("✅ FCM token successfully sent to backend after login");
        } else {
          debugPrint(
            "⚠️ Failed to send FCM token to backend after login - will retry on token refresh",
          );
        }

        // Setup token refresh listener to automatically update backend when token changes
        fcmTokenService.setupTokenRefreshListener(userToken);
        debugPrint("✅ FCM token refresh listener setup complete");

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) {
              var complaintStepOne = ComplaintStepOne(data: {}, userToken: '');
              return complaintStepOne;
            },
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "حدث خطأ أثناء تسجيل الدخول";
      });
      print("Login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).login)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: AppTextField(
                  labelText: AppLocalizations.of(context).mobileNumberOrEmail,
                  controller: identifierController,
                  myIcon: const Icon(Icons.person),
                  validator: validateIdentifier,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: AppTextField(
                  labelText: AppLocalizations.of(context).password,
                  controller: passwordController,
                  obscureText: obscurePassword,
                  myIcon: const Icon(Icons.lock),
                  validator: validatePassword,
                  traillingIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : AppButton(
                      text: AppLocalizations.of(context).login,
                      onTap: login,
                    ),

              const SizedBox(height: 15),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            ],
          ),
        ),
      ),
    );
  }
}
