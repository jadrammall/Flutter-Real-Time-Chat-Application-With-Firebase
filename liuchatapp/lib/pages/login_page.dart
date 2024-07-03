import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liuchatapp/consts.dart';
import 'package:liuchatapp/services/alert_service.dart';
import 'package:liuchatapp/services/auth_service.dart';
import 'package:liuchatapp/services/navigation_service.dart';
import 'package:liuchatapp/widgets/custom_form_field.dart';
import 'package:get_it/get_it.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GetIt _getIt = GetIt.instance;
  final GlobalKey<FormState> _loginformKey = GlobalKey();
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  String? email,password;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF332e2e,),
      resizeToAvoidBottomInset: false,
      body: _buildUI(),
    );
  }

  Widget _buildUI(){
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0
        ),
        child: Column(
          children: [
            _headerText(),
            _loginForm(),
            _createAnAccountLink(),
          ],
        ),
      ),
    );
  }

  Widget _headerText(){
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi, Welcome Back!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            "Hello again, you've been missed",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          )
        ],
      ),
    );
  }

  Widget _loginForm(){
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.4,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height * 0.05,
      ),
      child: Form(
        key: _loginformKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomFormField(
              label: "Email address",
              height: MediaQuery.sizeOf(context).height * 0.1,
              hintText: "Enter your email",
              validationRegEx: EMAIL_VALIDATION_REGEX,
              onSaved: (value) {
                setState(() {
                  email = value;
                });
              },
            ),
            CustomFormField(
              label: "Password",
              obscureText: true,
              height: MediaQuery.sizeOf(context).height * 0.1,
              hintText: "Enter your password",
              validationRegEx: PASSWORD_VALIDATION_REGEX,
              onSaved: (value) {
                setState(() {
                  password = value;
                });
              },
            ),
            _loginButton(),
          ],
        ),
      ),
    );
  }

  Widget _loginButton(){
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 40.0,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Colors.purple,
        child: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        onPressed: () async {
          if (_loginformKey.currentState?.validate() ?? false) {
            _loginformKey.currentState?.save();
            bool result = await _authService.login(email!, password!);
            print(result);
            if (result){
              await FirebaseFirestore.instance.collection('users').doc(_authService.user!.uid).update({'status': 'Active now',});
              _navigationService.pushReplacementNamed("/home");
            } else {
              _alertService.showToast(text: "Failed to login, Please try again!",icon: Icons.error);
            }
          }
        },
      ),
    );
  }

  Widget _createAnAccountLink(){
    return Expanded(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
                "Don't have an account? ",
              style: TextStyle(
                  color: Colors.purple
              ),
            ),
            GestureDetector(
              onTap: (){
                _navigationService.pushNamed("/register");
              },
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
    );
  }
}