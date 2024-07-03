import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:liuchatapp/models/user_profile.dart';
import 'package:liuchatapp/services/auth_service.dart';
import 'package:liuchatapp/services/database_service.dart';
import 'package:liuchatapp/services/media_service.dart';
import 'package:liuchatapp/services/storage_service.dart';
import 'package:liuchatapp/utils.dart';

import '../models/chat.dart';
import '../models/message.dart';

class ChatPage extends StatefulWidget {

  final UserProfile chatUser;

  const ChatPage({super.key, required this.chatUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;

  ChatUser? currentUser, otherUser;

  @override
  void initState(){
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    currentUser = ChatUser(
        id: _authService.user!.uid,
        firstName: _authService.user!.displayName
    );
    otherUser = ChatUser(
        id: widget.chatUser.uid!,
        firstName: widget.chatUser.name,
        profileImage: widget.chatUser.pfpURL
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF332e2e,),
      appBar: AppBar(
        backgroundColor: const Color(0xFF332e2e,),
        title: Text(
          widget.chatUser.name!,
          style: const TextStyle(
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
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          image: DecorationImage(
                            image: NetworkImage(otherUser!.profileImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            icon: CircleAvatar(
              backgroundImage: NetworkImage(otherUser!.profileImage!),
            ),
          ),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI(){
    return StreamBuilder(
        stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
        builder: (context, snapshot) {
          Chat? chat = snapshot.data?.data();
          List<ChatMessage> messages = [];
          if (chat != null && chat.messages != null){
            messages = _generateChatMessagesList(chat.messages!);
          }
          return DashChat(
            messageOptions: const MessageOptions(
              showOtherUsersAvatar: true,
              showTime: true,
              currentUserContainerColor: Colors.purple,
            ),
            inputOptions: InputOptions(
              alwaysShowSend: true,
              sendButtonBuilder: (onPressed) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.purple), // Change icon color if needed
                    onPressed: onPressed,
                  ),
                );
              },
              trailing: [
                _mediaMessageButton()
              ],
            ),
            currentUser: currentUser!,
            onSend: _sendMessage,
            messages: messages,
          );
        }
    );
  }

  Future <void> _sendMessage(ChatMessage chatMessage) async {
    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        Message message = Message(
            senderID: chatMessage.user.id,
            content: chatMessage.medias!.first.url,
            messageType: MessageType.Image,
            sentAt: Timestamp.fromDate(chatMessage.createdAt)
        );
        await _databaseService.sendChatMessage(
            currentUser!.id,
            otherUser!.id,
            message
        );
      }
    } else {
      Message message = Message(
          senderID: currentUser!.id,
          content: chatMessage.text,
          messageType: MessageType.Text,
          sentAt: Timestamp.fromDate(chatMessage.createdAt)
      );
      await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message
      );
    }

  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messsages) {
    List<ChatMessage> chatMessages = messsages.map((m){
      if (m.messageType == MessageType.Image){
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            medias: [
              ChatMedia(
                  url: m.content!,
                  fileName: "",
                  type: MediaType.image
              )
            ],
            createdAt:  m.sentAt!.toDate()
        );
      } else {
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            text: m.content!,
            createdAt: m.sentAt!.toDate()
        );
      }
    }).toList();
    chatMessages.sort(
            (a,b) {
              return b.createdAt.compareTo(a.createdAt);
            }
    );
    return chatMessages;
  }

  Widget _mediaMessageButton(){
    return IconButton(
        onPressed: () async {
          File? file = await _mediaService.getImageFromGallery();
          if (file != null){
            String chatID = generateChatID(
                uid1: currentUser!.id,
                uid2: otherUser!.id
            );
            String? downloadURL = await _storageService.uploadImageToChat(
                file: file,
                chatID: chatID
            );
            if (downloadURL != null){
              ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                        url: downloadURL,
                        fileName: "",
                        type: MediaType.image
                    )
                  ]
              );
              _sendMessage(chatMessage);
            }
          }
        },
        icon: const Icon(
          Icons.image,
          color: Colors.purple,
        )
    );
  }
}
