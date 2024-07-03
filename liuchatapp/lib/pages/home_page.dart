import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:liuchatapp/models/user_profile.dart';
import 'package:liuchatapp/pages/chat_page.dart';
import 'package:liuchatapp/pages/edit_user_page.dart';
import 'package:liuchatapp/services/alert_service.dart';
import 'package:liuchatapp/services/auth_service.dart';
import 'package:liuchatapp/services/database_service.dart';
import 'package:liuchatapp/widgets/chat_tile.dart';

import '../services/navigation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF332e2e,),
      appBar: AppBar(
        backgroundColor: const Color(0xFF332e2e,),
        title: const Text(
          "Messages",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold
          ),
        ),
        leading: IconButton(
          onPressed: () {
            _navigationService.push(
              MaterialPageRoute(
                builder: (context) => const EditUserPage(),
              ),
            );
          },
          icon: const Icon(
            Icons.settings,
            color: Colors.purple,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(_authService.user!.uid).update({'status': 'Offline',});
              bool result = await _authService.logout();
              if (result) {
                _alertService.showToast(
                  text: "Successfully logged out!",
                  icon: Icons.check,
                );
                _navigationService.pushReplacementNamed("/login");
              }
            },
            color: Colors.purple,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
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
            _buildSearchBar(),
            Expanded(child: _chatsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search, color: Colors.purple),
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _chatsList() {
    return StreamBuilder(
      stream: _databaseService.getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Unable to load data."),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final users = snapshot.data!.docs;
          users.sort((a, b) {
            Timestamp createdAtA = a['createdAt'];
            Timestamp createdAtB = b['createdAt'];
            return createdAtB.toDate().compareTo(createdAtA.toDate());
          });

          final filteredUsers = users.where((user) {
            final userName = user['name'].toString().toLowerCase();
            final userCampus = user['campus'].toString().toLowerCase();
            final userMajor = user['major'].toString().toLowerCase();
            final query = _searchQuery.toLowerCase();

            return userName.contains(query) || userCampus.contains(query) || userMajor.contains(query);
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(
              child: Text("No users found."),
            );
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              UserProfile user = filteredUsers[index].data();
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                ),
                child: Column(
                  children: [
                    const Divider(
                      height: 10,
                      thickness: 0.5,
                      color: Colors.white60,
                    ),
                    ChatTile(
                      userProfile: user,
                      onTap: () async {
                        final chatExists = await _databaseService.checkChatExists(
                            _authService.user!.uid,
                            user.uid!
                        );
                        if (!chatExists) {
                          await _databaseService.createNewChat(
                              _authService.user!.uid,
                              user.uid!
                          );
                        }
                        _navigationService.push(
                          MaterialPageRoute(
                            builder: (context) => ChatPage(chatUser: user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
