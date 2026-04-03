import 'package:flutter/material.dart';
import 'package:my_first_project/main.dart';

class MyBigButton extends StatelessWidget {
  final Function()? onTap;
  final String label;

  const MyBigButton({super.key, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(label, style: TextStyle(color: NMColors.text)),
    );
  }
}
