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
              colors: [Colors.green, const Color.fromARGB(255, 197, 249, 192)],
              begin: Alignment.topRight,
              end: AlignmentGeometry.bottomLeft,
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
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    border: Border.all(width: 10),
                    borderRadius: BorderRadius.circular(8),
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
