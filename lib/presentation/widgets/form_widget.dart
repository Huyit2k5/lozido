import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class CustomLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const CustomLabel({super.key, required this.label, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          children: [
            if (isRequired)
            const TextSpan(
              text: " *",
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final VoidCallback toggle;

  const PasswordField({
    super.key,
    required this.hint,
    required this.obscure,
    required this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }
}

class RequirementItem extends StatelessWidget {
  final String text;

  const RequirementItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}

class SupportOption extends StatelessWidget {
  final IconData icon;
  final String text;

  const SupportOption({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: Colors.green),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
