import 'package:flutter/material.dart';

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
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          prefixIcon: Icon(icon),
          prefixIconColor: Colors.green,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.green),

          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 7, 239, 15),
              width: 3,
            ),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        obscureText: obscureText,
      ),
    );
  }
}
