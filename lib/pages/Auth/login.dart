import 'package:flutter/material.dart';
import 'package:my_first_project/components/BigButton.dart';
import 'package:my_first_project/components/inputTextField.dart';
import 'package:my_first_project/main.dart';
import 'package:my_first_project/pages/depricated/homepage.dart';
import 'package:my_first_project/pages/shell.dart';
import 'package:pocketbase/pocketbase.dart';

class LoginPage extends StatefulWidget {
  // Changed to StatefulWidget
  const LoginPage({super.key}); // Added const constructor

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //----------------
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  //--------functions-------

  void Sign_in() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AppShell()),
    );
  }

  //-----------------
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NMColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
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
              MyInputTextField(
                controller: usernameController,
                hintText: "Username",
                obscureText: false,
                icon: Icons.person,
              ),
              //textfield password
              MyInputTextField(
                controller: passwordController,
                hintText: "password",
                obscureText: true,
                icon: Icons.key,
              ),
              //password

              //sign-in|sign-up button
              SizedBox(height: 20),
              MyBigButton(onTap: Sign_in, label: "Log in"),
              SizedBox(height: 10),
              MyBigButton(onTap: Sign_in, label: "Sign up"),
              SizedBox(height: 60),
              Divider(),

              //etc
            ],
          ),
        ),
      ),
    );
  }
}
