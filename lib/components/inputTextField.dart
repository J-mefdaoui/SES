import 'package:flutter/material.dart';
import 'package:my_first_project/main.dart';

class MyInputTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;
  final IconData icon;

  const MyInputTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: EdgeInsetsGeometry.directional(
        start: 50,
        end: 50,
        top: 10,
        bottom: 10,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          prefixIconColor: Colors.green,
          hintText: hintText,
        ),
        obscureText: obscureText,
      ),
    );
  }
}
