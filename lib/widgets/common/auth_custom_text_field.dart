import 'package:flutter/material.dart';
import '../../utils/colors.dart'; // Ensure this import path is correct

class AuthCustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText; // Changed from 'label' to 'hintText'
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType; // Added for completeness, if not already present

  const AuthCustomTextField({
    super.key,
    required this.controller,
    required this.hintText, // Updated constructor parameter
    required this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text, // Default value
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText, // Using hintText here
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary, // Styling for hint text
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.textSecondary, // Consistency for icon color
        ),
        suffixIcon: suffixIcon,
        // The rest of the InputDecoration styling (border, contentPadding etc.)
        // is applied via ThemeData in main.dart, which is good.
      ),
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary, // Style for the input text itself
      ),
    );
  }
}