import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:madee_chat_app/allProviders/auth_provider.dart';
import 'package:madee_chat_app/allScreens/home_page.dart';
import 'package:madee_chat_app/allScreens/register_page.dart';
import 'package:madee_chat_app/allWidgets/loading_view.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController(text: '');
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
      backgroundColor: Colors.black87,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Image.asset('images/back.png'),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () async {
                  bool isSuccess = await authProvider.handleSigin();
                  if (isSuccess) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => HomePage()));
                  }
                },
                child: Image.asset('images/google_login.jpg'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 0,
              ),
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                width: double.infinity,
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
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
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
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
                            controller: passwordController,
                            obscureText: true,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              hintText: "your Password",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: Container(
                        width: 150,
                        height: 50,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            bool isSuccess = await authProvider.loginHandle(
                                email: emailController.text,
                                password: passwordController.text);
                            if (isSuccess) {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HomePage()));
                            }
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Text('Dont have an account ?'),
                          SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RegisterPage()));
                            },
                            child: Text(
                              'Register!',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            authProvider.status == Status.authenticating
                ? LoadingView()
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
