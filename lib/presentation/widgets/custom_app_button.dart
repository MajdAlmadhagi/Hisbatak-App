import 'package:flutter/material.dart';
import 'package:hisbatak_app/core/theme/app_theme.dart';

class CustomAppButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? text;
  final bool isLoading;
  final bool isDark;

  const CustomAppButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.text,
    this.isLoading = false,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: onPressed,
        child: Icon(icon, size: 20, color: context.appTextPrimary),
      ),
    );
  }
}
