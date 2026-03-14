import 'package:flutter/material.dart';
import 'package:my_first_project/components/BigButton.dart';
import 'package:my_first_project/components/inputTextField.dart';
import 'package:my_first_project/pages/homepage.dart';

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
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  } // can this function change to go to a homepage ?

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
      backgroundColor: const Color.fromARGB(255, 223, 240, 224),
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
              MyBigButton(onTap: Sign_in, label: "Log in"),
              ElevatedButton(
                onPressed: Sign_in,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "Sign up",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              //etc
            ],
          ),
        ),
      ),
    );
  }
}
