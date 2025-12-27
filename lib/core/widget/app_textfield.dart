import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    Key? key,
    // required this.hintText,
    this.labelText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.myIcon,
    this.traillingIcon,
    this.width = 330,
    this.height = 70,
  }) : super(key: key);

  // final String hintText;
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
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            // hintText: hintText,
            labelText: labelText,

            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.1),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),

            labelStyle: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),

            prefixIcon: myIcon,
            suffixIcon: traillingIcon,

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 1.5),
            ),

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
