import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  String? uid;
  String? name;
  String? pfpURL;
  String? status;
  String? email;
  Timestamp? createdAt;
  String? campus;
  String? major;

  UserProfile({
    required this.uid,
    required this.name,
    required this.pfpURL,
    required this.status,
    required this.email,
    required this.createdAt,
    required this.campus,
    required this.major,
  });

  UserProfile.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    name = json['name'];
    pfpURL = json['pfpURL'];
    status = json['status'];
    email = json ['email'];
    createdAt = json['createdAt'];
    campus = json['campus'];
    major = json['major'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['pfpURL'] = pfpURL;
    data['uid'] = uid;
    data['status'] = status;
    data['email'] = email;
    data['createdAt'] = createdAt;
    data['campus'] = campus;
    data['major'] = major;
    return data;
  }
}