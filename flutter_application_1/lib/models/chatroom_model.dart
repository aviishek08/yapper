import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  String? chatroomid;
  Map<String, bool>? participants; // Changed to bool for clarity
  String? lastMessage;
  DateTime? lastMessageSentTime;
  DateTime? lastMessageSeenTime;

  ChatRoomModel({
    this.chatroomid,
    this.participants,
    this.lastMessage,
    this.lastMessageSentTime,
    this.lastMessageSeenTime,
  });

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomid = map["chatroomid"];
    participants = Map<String, bool>.from(map["participants"]);
    lastMessage = map["lastmessage"];
    lastMessageSentTime = (map["lastMessageSentTime"] as Timestamp?)?.toDate();
    lastMessageSeenTime = (map["lastMessageSeenTime"] as Timestamp?)?.toDate();
  }

  Map<String, dynamic> toMap() {
    return {
      "chatroomid": chatroomid,
      "participants": participants,
      "lastmessage": lastMessage,
      "lastMessageSentTime": lastMessageSentTime,
      "lastMessageSeenTime": lastMessageSeenTime,
    };
  }

  ChatRoomModel copyWith({
    String? chatroomid,
    Map<String, bool>? participants,
    String? lastMessage,
    DateTime? lastMessageSentTime,
    DateTime? lastMessageSeenTime,
  }) {
    return ChatRoomModel(
      chatroomid: chatroomid ?? this.chatroomid,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSentTime: lastMessageSentTime ?? this.lastMessageSentTime,
      lastMessageSeenTime: lastMessageSeenTime ?? this.lastMessageSeenTime,
    );
  }
}
