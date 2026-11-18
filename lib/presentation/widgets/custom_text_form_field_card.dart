import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CustomTextFormFieldCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;

  const CustomTextFormFieldCard({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textDirection: textDirection,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.appTextPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: context.appTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
