import 'package:flutter/material.dart';
import '../../../Utils/colors.dart';

class BrandButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;
  final bool isLoading;
  final EdgeInsetsGeometry? margin;

  const BrandButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
                colors: [LarosaColors.secondary, LarosaColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: FilledButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        onPressed: isEnabled && !isLoading ? onPressed : null,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }
}