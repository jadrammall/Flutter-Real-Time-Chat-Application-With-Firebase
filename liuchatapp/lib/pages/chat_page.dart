import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get_it/get_it.dart';
import 'package:liuchatapp/models/user_profile.dart';
import 'package:liuchatapp/services/auth_service.dart';
import 'package:liuchatapp/services/database_service.dart';
import 'package:liuchatapp/services/media_service.dart';
import 'package:liuchatapp/services/storage_service.dart';
import 'package:liuchatapp/utils.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/document_service.dart';
import 'preview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late DocumentService _documentService;

  ChatUser? currentUser, otherUser;

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _documentService = _getIt.get<DocumentService>();

    currentUser = ChatUser(
      id: _authService.user!.uid,
      firstName: _authService.user!.displayName,
    );
    otherUser = ChatUser(
      id: widget.chatUser.uid!,
      firstName: widget.chatUser.name,
      profileImage: widget.chatUser.pfpURL,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF332e2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF332e2e),
        title: Column(
          children: [
            Text(
              widget.chatUser.name!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.chatUser.campus} - ${widget.chatUser.major}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
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
                            fit: BoxFit.contain,
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

  Widget _buildUI() {
    return StreamBuilder(
      stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
      builder: (context, snapshot) {
        Chat? chat = snapshot.data?.data();
        List<ChatMessage> messages = [];
        if (chat != null && chat.messages != null) {
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
                  icon: const Icon(
                    Icons.send,
                    color: Colors.purple,
                  ),
                  onPressed: onPressed,
                ),
              );
            },
            trailing: [
              _mediaMessageSpeedDial(),
            ],
          ),
          currentUser: currentUser!,
          onSend: _sendMessage,
          messages: messages,
        );
      },
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    if (chatMessage.medias?.isNotEmpty ?? false) {
      final firstMedia = chatMessage.medias!.first;
      MessageType messageType;
      if (firstMedia.type == MediaType.image) {
        messageType = MessageType.Image;
      } else if (firstMedia.type == MediaType.video) {
        messageType = MessageType.Video;
      } else if (firstMedia.type == MediaType.file) {
        messageType = MessageType.File;
      } else {
        messageType = MessageType.Text;
      }

      Message message = Message(
        senderID: chatMessage.user.id,
        content: firstMedia.url,
        messageType: messageType,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );

      try {
        await _databaseService.sendChatMessage(currentUser!.id, otherUser!.id, message);
      } catch (e) {
        print("Failed to send message: $e");
      }
    } else {
      Message message = Message(
        senderID: currentUser!.id,
        content: chatMessage.text,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );

      try {
        await _databaseService.sendChatMessage(currentUser!.id, otherUser!.id, message);
      } catch (e) {
        print("Failed to send message: $e");
      }
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          medias: [
            ChatMedia(
              url: m.content!,
              fileName: "",
              type: MediaType.image,
            )
          ],
          createdAt: m.sentAt!.toDate(),
        );
      } else if (m.messageType == MessageType.Video) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          medias: [
            ChatMedia(
              url: m.content!,
              fileName: "",
              type: MediaType.video,
            )
          ],
          createdAt: m.sentAt!.toDate(),
        );
      } else if (m.messageType == MessageType.File) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: m.content!,
          createdAt: m.sentAt!.toDate(),
        );
      } else {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: m.content!,
          createdAt: m.sentAt!.toDate(),
        );
      }
    }).toList();
    chatMessages.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt);
    });
    return chatMessages;
  }

  Widget _mediaMessageSpeedDial() {
    return SpeedDial(
      spaceBetweenChildren: 4,
      childPadding: const EdgeInsets.all(5),
      backgroundColor: Colors.purple,
      buttonSize: const Size(45.0, 45.0),
      overlayOpacity: 0.5,
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.image),
          backgroundColor: Colors.purple,
          shape: const CircleBorder(),
          onTap: () async {
            await _handleMediaSelection(isVideo: false);
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.videocam),
          backgroundColor: Colors.purple,
          shape: const CircleBorder(),
          onTap: () async {
            await _handleMediaSelection(isVideo: true);
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.attach_file),
          backgroundColor: Colors.purple,
          shape: const CircleBorder(),
          onTap: () async {
            await _handleDocumentSelection();
          },
        ),
      ],
    );
  }

  Future<void> _handleMediaSelection({required bool isVideo}) async {
    File? file = await _mediaService.getMediaFromGallery(isVideo: isVideo);
    if (file != null) {
      MediaType mediaType = isVideo ? MediaType.video : MediaType.image;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            file: file,
            mediaType: mediaType,
            onSend: (file) async {
              String chatID = generateChatID(uid1: currentUser!.id, uid2: otherUser!.id);
              String? downloadURL = isVideo
                  ? await _storageService.uploadVideoToChat(file: file, chatID: chatID)
                  : await _storageService.uploadImageToChat(file: file, chatID: chatID);
              if (downloadURL != null) {
                ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                      url: downloadURL,
                      fileName: file.path.split('/').last,
                      type: mediaType,
                    ),
                  ],
                );
                _sendMessage(chatMessage);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleDocumentSelection() async {
    File? file = await _documentService.pickDocument();
    if (file != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            file: file,
            mediaType: MediaType.file,
            onSend: (file) async {
              String chatID = generateChatID(uid1: currentUser!.id, uid2: otherUser!.id);
              String? downloadURL = await _storageService.uploadDocumentToChat(file: file, chatID: chatID);
              if (downloadURL != null) {
                ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                      url: downloadURL,
                      fileName: file.path.split('/').last,
                      type: MediaType.file,
                    ),
                  ],
                );
                _sendMessage(chatMessage);
              }
            },
          ),
        ),
      );
    }
  }
}