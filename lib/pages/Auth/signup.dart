import 'package:flutter/material.dart';
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
                Image.asset(
                  'assets/images/LogoBayanti.png',
                  width: 400,
                  height: 400,
                ),

                SizedBox(),

                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 10,
                      color: const Color.fromARGB(255, 83, 172, 61),
                    ),
                    borderRadius: BorderRadius.circular(8),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
