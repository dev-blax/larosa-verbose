import 'package:flutter/material.dart';

Widget fullNameInput({
  required TextEditingController controller,
  required Function(String) onChanged,
  String? errorMessage,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Full Name",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Enter your full name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.person),
          // errorText: errorMessage,
        ),
        onChanged: onChanged,
      ),
      if (errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
    ],
  );
}