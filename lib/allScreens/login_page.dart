import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:madee_chat_app/allProviders/auth_provider.dart';
import 'package:madee_chat_app/allScreens/home_page.dart';
import 'package:madee_chat_app/allWidgets/loading_view.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      body: Column(
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
          authProvider.status == Status.authenticating
              ? LoadingView()
              : SizedBox(),
        ],
      ),
    );
  }
}
