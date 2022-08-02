import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../allProviders/auth_provider.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController emailController = TextEditingController(text: '');
  TextEditingController nameController = TextEditingController(text: '');
  TextEditingController passwordController = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "sign in fail");
        break;

      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "sign in canceled");
        break;

      case Status.authenticated:
        Fluttertoast.showToast(msg: "sign in successfully");
        break;

      default:
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          Center(
            child: Text(
              'Register here',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Container(
            margin: EdgeInsets.only(bottom: 20, left: 30, right: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name',
                ),
                SizedBox(
                  height: 6,
                ),
                TextFormField(
                  controller: nameController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: "your Name",
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 20, left: 30, right: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                ),
                SizedBox(
                  height: 6,
                ),
                TextFormField(
                  controller: emailController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: "your email",
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 20, left: 30, right: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password',
                ),
                SizedBox(
                  height: 6,
                ),
                TextFormField(
                  obscureText: true,
                  controller: passwordController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: "your password",
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 60),
            child: Container(
              width: 150,
              height: 50,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () async {
                  bool isSuccess = await authProvider.registerHandle(
                    nickname: nameController.text,
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  if (isSuccess) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => HomePage()));
                  }
                },
                child: Text(
                  'Register',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
