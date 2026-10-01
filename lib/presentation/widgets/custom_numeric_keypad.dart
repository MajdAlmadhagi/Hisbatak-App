import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// [CustomNumericKeypad] provides the fintech numeric keypad matching Stitch Screen 4.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
class CustomNumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onDelete;

  const CustomNumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
  });

  Widget _buildKey(BuildContext context, String value,
      {IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Material(
          color: context.appCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: context.appBorder, width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap ?? () => onKeyPressed(value),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: context.appTextPrimary, size: 20)
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildKey(context, '1'),
            _buildKey(context, '2'),
            _buildKey(context, '3'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '4'),
            _buildKey(context, '5'),
            _buildKey(context, '6'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '7'),
            _buildKey(context, '8'),
            _buildKey(context, '9'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '.'),
            _buildKey(context, '0'),
            _buildKey(context, '',
                icon: Icons.backspace_outlined, onTap: onDelete),
          ],
        ),
      ],
    );
  }
}
