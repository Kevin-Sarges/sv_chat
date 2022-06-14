// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:new_chat/constants/all_constants.dart';

class ChatUser extends Equatable {
  late String id;
  late String photoUrl;
  late String displayName;
  late String phoneNumber;
  late String aboutMe;

  ChatUser({
    required this.id,
    required this.photoUrl,
    required this.displayName,
    required this.phoneNumber,
    required this.aboutMe,
  });

  ChatUser copyWith({
    String? id,
    String? photoUrl,
    String? nickname,
    String? phoneNumber,
    String? email,
  }) =>
      ChatUser(
        id: id ?? this.id,
        photoUrl: photoUrl ?? this.photoUrl,
        displayName: nickname ?? displayName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        aboutMe: email ?? aboutMe,
      );

  Map<String, dynamic> toJson() => {
        FirestoreConstants.displayName: displayName,
        FirestoreConstants.photoUrl: photoUrl,
        FirestoreConstants.phoneNumber: phoneNumber,
        FirestoreConstants.aboutMe: aboutMe,
      };

  factory ChatUser.fromDocument(DocumentSnapshot snapshot) {
    String photoUrl = '';
    String nickname = '';
    String phoneNumber = '';
    String aboutMe = '';

    try {
      photoUrl = snapshot.get(FirestoreConstants.photoUrl);
      nickname = snapshot.get(FirestoreConstants.displayName);
      phoneNumber = snapshot.get(FirestoreConstants.phoneNumber);
      aboutMe = snapshot.get(FirestoreConstants.aboutMe);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return ChatUser(
      id: snapshot.id,
      photoUrl: photoUrl,
      displayName: nickname,
      phoneNumber: phoneNumber,
      aboutMe: aboutMe,
    );
  }

  @override
  List<Object?> get props => [id, photoUrl, displayName, phoneNumber, aboutMe];
}
