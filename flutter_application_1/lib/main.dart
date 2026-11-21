import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/firebase_helper.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/pages/complete_profile.dart';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:flutter_application_1/pages/signup_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
    await Firebase.initializeApp(options: FirebaseOptions(
      apiKey: "AIzaSyCck8z3VPfy1sI0T2_l1r3Ia6kwuvLwAeo",
  authDomain: "newproj-ecd59.firebaseapp.com",
  projectId: "newproj-ecd59",
  storageBucket: "newproj-ecd59.appspot.com",
  messagingSenderId: "518944726935",
  appId: "1:518944726935:web:11d2655d77bc8282f22ed2",
  measurementId: "G-WZWWVHQ5XB"));
  }
  Firebase.initializeApp();

  User? currentUser = FirebaseAuth.instance.currentUser;
  if(currentUser != null) {
    // Logged In
    UserModel? thisUserModel = await FirebaseHelper.getUserModelById(currentUser.uid);
    if(thisUserModel != null) {
      runApp(MyAppLoggedIn(userModel: thisUserModel, firebaseUser: currentUser));
    }
    else {
      runApp(MyApp());
    }
  }
  else {
    
    runApp(MyApp());
  }

}

class MyApp extends StatelessWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

// Already Logged In
class MyAppLoggedIn extends StatelessWidget {
  final UserModel userModel;
  final User firebaseUser;

  const MyAppLoggedIn({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(userModel: userModel, firebaseUser: firebaseUser),
    );
  }
}
     