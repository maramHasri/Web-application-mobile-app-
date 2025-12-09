import 'package:flutter/material.dart';
import 'package:flutter_internet_application/core/resource/color.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    Key? key,
    required this.hintText,
    this.labelText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.myIcon,
    this.traillingIcon,
    this.width = 330,
    this.height = 70,
  }) : super(key: key);

  final String hintText;
  final String? labelText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? myIcon; // أيقونة البداية
  final Widget? traillingIcon; // أيقونة النهاية
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,

            filled: true,
            fillColor: Colors.white.withOpacity(0.1),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),

            labelStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),

            prefixIcon: myIcon,
            suffixIcon: traillingIcon,

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),

            // ⭐ هنا أضفتهم — نفس الشكل فقط لون أحمر
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}
