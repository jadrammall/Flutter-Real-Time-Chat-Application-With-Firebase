import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  StorageService();

  Future<void> deleteUserPfp({required String uid}) async {
    try {
      Reference fileRef = FirebaseStorage.instance.ref('users/pfps/$uid.jpg');
      await fileRef.delete();
      print('File deleted successfully');
    } catch (e) {
      print('Failed to delete file: $e');
    }
  }

  Future<String?> uploadUserPfp({required File file, required String uid}) async {
    Reference fileRef = _firebaseStorage
        .ref('users/pfps')
        .child('$uid${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then(
          (p) {
        if (p.state == TaskState.success) {
          return fileRef.getDownloadURL();
        }
      },
    );
  }

  Future<String?> uploadImageToChat({required File file, required String chatID}) async {
    Reference fileRef = _firebaseStorage
        .ref('chats/$chatID')
        .child('${DateTime.now().toIso8601String()}${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then(
          (p) {
        if (p.state == TaskState.success) {
          return fileRef.getDownloadURL();
        }
      },
    );
  }

  Future<String?> uploadVideoToChat({required File file, required String chatID}) async {
    Reference fileRef = _firebaseStorage
        .ref('chats/$chatID')
        .child('${DateTime.now().toIso8601String()}${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then(
          (p) {
        if (p.state == TaskState.success) {
          return fileRef.getDownloadURL();
        }
      },
    );
  }

  Future<String?> uploadDocumentToChat({required File file, required String chatID}) async {
    String fileName = p.basename(file.path);
    Reference fileRef = _firebaseStorage
        .ref('chats/$chatID')
        .child('$fileName');
    UploadTask task = fileRef.putFile(file);
    return task.then(
          (p) {
        if (p.state == TaskState.success) {
          return fileRef.getDownloadURL();
        }
      },
    );
  }

}
