import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/ui_helper.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:flutter_application_1/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isHovering = false;  // For detecting hover state

  void checkValues() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email == "" || password == "") {
      UIHelper.showAlertDialog(context, "Incomplete Data", "Please fill all the fields");
    } else {
      logIn(email, password);
    }
  }

  void logIn(String email, String password) async {
    UserCredential? credential;

    UIHelper.showLoadingDialog(context, "Logging In..");

    try {
      credential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (ex) {
      Navigator.pop(context);

      UIHelper.showAlertDialog(context, "An error occurred", ex.message.toString());
    }

    if (credential != null) {
      String uid = credential.user!.uid;

      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      UserModel userModel = UserModel.fromMap(userData.data() as Map<String, dynamic>);

      // Go to HomePage
      print("Log In Successful!");
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return HomePage(userModel: userModel, firebaseUser: credential!.user!);
          },
        ),
      );
    }
  }

  void resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      UIHelper.showAlertDialog(context, "Password Reset", "Password reset email has been sent to $email");
    } on FirebaseAuthException catch (ex) {
      UIHelper.showAlertDialog(context, "An error occurred", ex.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 40,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Yapper",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: "Email Address"),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Password"),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          isHovering = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          isHovering = false;
                        });
                      },
                      child: GestureDetector(
                        onTap: () {
                          String email = emailController.text.trim();
                          if (email.isEmpty) {
                            UIHelper.showAlertDialog(context, "Error", "Please enter your email address to reset your password.");
                          } else {
                            resetPassword(email);
                          }
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: isHovering ? Colors.purple : Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  CupertinoButton(
                    onPressed: () {
                      checkValues();
                    },
                    color: Theme.of(context).colorScheme.secondary,
                    child: Text("Log In"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: TextStyle(fontSize: 16),
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return SignUpPage();
                    },
                  ),
                );
              },
              child: Text(
                "Sign Up",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
