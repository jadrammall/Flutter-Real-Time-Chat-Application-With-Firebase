import 'package:flutter/material.dart';

class DropdownFormField extends StatelessWidget {
  final String label;
  final String hint;
  final double height;
  final void Function(String?) onSaved;
  final List<String> options;

  const DropdownFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.height,
    required this.onSaved,
    required this.options,
  });

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
          DropdownButtonFormField<String>(
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (String? newValue) {},
            onSaved: onSaved,
            hint: Text(hint),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
