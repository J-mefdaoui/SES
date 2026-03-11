import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 240, 224),
      body: SafeArea(
        child: Center(
          child: Column(
            children: const [
              SizedBox(height: 100),
              //logo
              Icon(Icons.lock, size: 100, color: Colors.green),
              SizedBox(height: 60),

              //message
              Text(
                "welcome back",
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              //textfield
              Padding(
                padding: EdgeInsetsGeometry.directional(
                  start: 50,
                  end: 50,
                  top: 25,
                  bottom: 10,
                ),
                child: TextField(
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              //textfield
              Padding(
                padding: EdgeInsetsGeometry.directional(
                  start: 50,
                  end: 50,
                  top: 10,
                  bottom: 50,
                ),
                child: TextField(
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              //password

              //sign-in|sign-up button

              //etc
            ],
          ),
        ),
      ),
    );
  }
}
