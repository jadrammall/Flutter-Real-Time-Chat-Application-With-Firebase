import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:liuchatapp/models/user_profile.dart';
import 'package:liuchatapp/services/alert_service.dart';
import 'package:liuchatapp/services/auth_service.dart';
import 'package:liuchatapp/services/database_service.dart';
import 'package:liuchatapp/services/storage_service.dart';
import '../consts.dart';
import '../services/media_service.dart';
import '../services/navigation_service.dart';
import '../widgets/custom_form_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String? email,password,name;
  File? selectedImage;
  bool isLoading = false;
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  final GetIt _getIt = GetIt.instance;
  late MediaService _mediaService;
  late NavigationService _navigationService;
  late AuthService _authService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  late AlertService _alertService;

  @override
  void initState() {
    super.initState();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _authService = _getIt.get<AuthService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF332e2e,),
      resizeToAvoidBottomInset: false,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15.0,
            vertical: 20.0,
          ),
          child: Column(
            children: [
                _headerText(),
              if (!isLoading) _registerForm(),
              if (!isLoading) _loginAccountLink(),
              if (isLoading) const Expanded(child: Center(child: CircularProgressIndicator()),),
            ],
          ),
        )
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
            "Let's get going!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            "Register an account using the form below",
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

  Widget _registerForm(){
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height * 0.05,
      ),
      child: Form(
        key: _registerFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _pfpSelectionField(),
            CustomFormField(
              label: "Name",
              height: MediaQuery.sizeOf(context).height * 0.1,
              hintText: "Enter your full name",
              validationRegEx: NAME_VALIDATION_REGEX,
              onSaved: (value) {
                setState(() {
                  name = value;
                });
              },
            ),
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
            _registerButton(),
          ],
        ),
      ),
    );
  }

  Widget _pfpSelectionField(){
    return GestureDetector(
      onTap: () async {
        File? file = await _mediaService.getImageFromGallery();
        if (file != null) {
          setState(() {
            selectedImage = file;
          });
        }
      },
      child: CircleAvatar(
        radius: MediaQuery.of(context).size.width *0.15,
        backgroundImage: selectedImage != null? FileImage(selectedImage!):NetworkImage(PLACEHOLDER_PFP) as ImageProvider,
      ),
    );
  }

  Widget _registerButton(){
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 40.0,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Colors.purple,
        child: const Text(
          "Register",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        onPressed: () async {
          setState(() {
            isLoading = true;
          });
          try {
            if ((_registerFormKey.currentState?.validate() ?? false ) && selectedImage != null){
              _registerFormKey.currentState?.save();
              bool result = await _authService.signup(email!, password!);
              if (result) {
                String? pfpURL = await _storageService.uploadUserPfp(
                    file: selectedImage!,
                    uid: _authService.user!.uid,
                );
                if (pfpURL != null) {
                  await _databaseService.createUserProfile(
                    userProfile: UserProfile(
                          uid: _authService.user!.uid,
                          name: name,
                          pfpURL: pfpURL,
                          status: "Active now",
                          email: email,
                          createdAt: Timestamp.now(),
                      ),
                  );
                  _alertService.showToast(
                      text: "User registered successfully!",
                      icon: Icons.check,
                  );
                  _navigationService.goBack();
                  _navigationService.pushReplacementNamed("/home");
                } else {
                  throw Exception("Unable to upload user's profile picture");
                }
              } else {
                throw Exception("Unable to register");
              }
            }
          } catch (e) {
            print(e);
            _alertService.showToast(
                text: "Failed to register, please try again",
                icon: Icons.error,
            );
          }
          setState(() {
            isLoading = false;
          });
        },
      ),
    );
  }

  Widget _loginAccountLink(){
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "Already have an account? ",
            style: TextStyle(
                color: Colors.purple
            ),
          ),
          GestureDetector(
            onTap: (){
              _navigationService.goBack();
            },
            child: const Text(
              "Login",
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

