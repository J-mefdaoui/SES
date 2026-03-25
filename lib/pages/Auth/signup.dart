import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_first_project/components/inputTextField.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void Sign_up() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 197, 249, 192),
                Colors.green.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: AlignmentGeometry.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: 100, bottom: 60),
                  child: Image.asset(
                    'assets/images/LogoBayanti.png',
                    width: 200,
                    height: 200,
                  ),
                ),

                SizedBox(),

                Container(
                  padding: EdgeInsets.only(top: 30, bottom: 30),
                  margin: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 10,
                      color: const Color(0xFF22B170).withOpacity(1),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                    color: const Color.fromARGB(255, 231, 231, 231),
                  ),
                  child: Column(
                    children: [
                      MyInputTextField(
                        controller: usernameController,
                        hintText: 'username',
                        obscureText: false,
                        icon: Icons.person,
                      ),
                      MyInputTextField(
                        controller: emailController,
                        hintText: "Email",
                        obscureText: false,
                        icon: Icons.mail,
                      ),
                      MyInputTextField(
                        controller: passwordController,
                        hintText: "password",
                        obscureText: true,
                        icon: Icons.key,
                      ),
                      MyInputTextField(
                        controller: passwordController,
                        hintText: "repeat password",
                        obscureText: true,
                        icon: Icons.key,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: Sign_up,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
