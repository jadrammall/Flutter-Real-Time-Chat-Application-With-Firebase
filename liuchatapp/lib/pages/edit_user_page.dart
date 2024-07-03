import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:liuchatapp/services/alert_service.dart';
import 'package:liuchatapp/services/media_service.dart';
import 'package:liuchatapp/services/navigation_service.dart';
import 'package:liuchatapp/services/storage_service.dart';
import '../consts.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final GetIt _getIt = GetIt.instance;
  final GlobalKey<FormState> _nameKey = GlobalKey();
  late AuthService _authService;
  late DatabaseService _databaseService;
  late NavigationService _navigationService;
  late StorageService _storageService;
  late MediaService _mediaService;
  late AlertService _alertService;
  String? _profilePictureUrl;
  File? _selectedImage;
  String? _myEmail;
  String? _myName;
  String? _newName;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _alertService = _getIt.get<AlertService>();
    _navigationService = _getIt.get<NavigationService>();
    _loadUserProfile();
  }


  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _myName = userProfileSnapshot.get('name');
        _myEmail = userProfileSnapshot.get('email');
        _profilePictureUrl = userProfileSnapshot.get('pfpURL');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF332e2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF332e2e),
        title: const Text(
          "Edit your info",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.purple,
        ),
        actions: [
          IconButton(
              onPressed: () {
                saveButton();
              },
              icon: const Icon(
                Icons.save
              )
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isLoading) const Expanded(child: Center(child: CircularProgressIndicator()),),
            if (!isLoading) SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pfpForm(),
                    const SizedBox(height: 16),
                    _nameForm(),
                    const SizedBox(height: 16),
                    _emailForm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _pfpForm() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                :NetworkImage(_profilePictureUrl!),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your name and add an\noptional profile picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    File? file = await _mediaService.getImageFromGallery();
                    if (file != null) {
                      setState(() {
                        _selectedImage = file;
                      });
                    }
                  },
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _nameForm(){
    return Form(
      key: _nameKey,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              validator: (value){
                if (value != null && NAME_VALIDATION_REGEX.hasMatch(value)) {
                  return null;
                }
                return "Enter a valid name";
              },
              onChanged: (value) {
                setState(() {
                  _newName = value;
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _myName,
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _emailForm(){
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email Address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _myEmail!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  saveButton () async {
    setState(() {
      isLoading = true;
    });
    try {
      if ((_nameKey.currentState?.validate() ?? false ) && _selectedImage != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_authService.user!.uid)
            .update({'name': _newName!});

        await _storageService.deleteUserPfp(uid: _authService.user!.uid);
        String? pfpURL = await _storageService.uploadUserPfp(
          file: _selectedImage!,
          uid: _authService.user!.uid,
        );

        if (pfpURL != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_authService.user!.uid)
              .update({'pfpURL': pfpURL});
        }
        _alertService.showToast(
          text: "Profile updated successfully!",
          icon: Icons.error,
        );
        _navigationService.pushReplacementNamed("/home");
      }
    } catch (e) {
      _alertService.showToast(
        text: "Failed to save your info,\nplease try again",
        icon: Icons.error,
      );
    }
    setState(() {
      isLoading = false;
    });
  }
}
