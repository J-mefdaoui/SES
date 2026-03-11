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
              //textfield user
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
              //textfield password
              Padding(
                padding: EdgeInsetsGeometry.directional(
                  start: 50,
                  end: 50,
                  top: 10,
                  bottom: 50,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                    ),
                    prefixIcon: Icon(Icons.key),
                    prefixIconColor: Colors.green,
                    hintText: "password",
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
                  obscureText: true,
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
