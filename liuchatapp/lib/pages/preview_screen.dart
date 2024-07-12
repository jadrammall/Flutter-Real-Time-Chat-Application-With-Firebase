import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PreviewScreen extends StatelessWidget {
  final File file;
  final MediaType mediaType;
  final Function(File file) onSend;

  const PreviewScreen({
    Key? key,
    required this.file,
    required this.mediaType,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF332e2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF332e2e),
        iconTheme: const IconThemeData(
          color: Colors.purple,
        ),
        title: const Text(
          'Preview',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.send,
              color: Colors.purple,
            ),
            onPressed: () {
              onSend(file);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: mediaType == MediaType.image
            ? Image.file(file)
            : mediaType == MediaType.video
                ? VideoPlayerScreen(file: file)
                : mediaType == MediaType.file
                    ? DocumentPreviewScreen(file: file)
                    : const Text('Preview not available',
                        style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File file;

  const VideoPlayerScreen({super.key, required this.file});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late vp.VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = vp.VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: vp.VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}

class DocumentPreviewScreen extends StatelessWidget {
  final File file;

  const DocumentPreviewScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final isPDF = file.path.endsWith('.pdf');

    return isPDF
        ? PDFView(
            filePath: file.path,
          )
        : const Center(
            child: Text(
              'No preview available for this document type',
              style: TextStyle(color: Colors.white),
            ),
          );
  }
}
