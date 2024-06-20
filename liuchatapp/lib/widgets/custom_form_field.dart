import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final String label;
  final String hintText;
  final double height;
  final RegExp validationRegEx;
  final bool obscureText;
  final void Function(String?) onSaved;

  const CustomFormField({super.key, required this.hintText, required this.height, required this.validationRegEx, this.obscureText = false, required this.label, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5.0,),
          TextFormField(
            style: const TextStyle(color: Colors.purple,),
            onSaved: onSaved,
            obscureText: obscureText,
            validator: (value){
              if (value != null && validationRegEx.hasMatch(value)) {
                return null;
              }
              return "Enter a valid ${hintText.toLowerCase()}";
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
