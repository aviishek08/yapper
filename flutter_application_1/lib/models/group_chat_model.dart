import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatRoomModel {
  String? chatroomid;
  String? groupName;
  String? groupImage;
  Map<String, dynamic>? participants;
  String? lastMessage;
  DateTime? lastMessageSentTime;
  DateTime? lastMessageSeenTime;
  List<String>? admins;

  GroupChatRoomModel({
    this.chatroomid,
    this.groupName,
    this.groupImage,
    this.participants,
    this.lastMessage,
    this.lastMessageSentTime,
    this.lastMessageSeenTime,
    this.admins,
  });

  GroupChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomid = map["chatroomid"];
    groupName = map["groupName"];
    groupImage = map["groupImage"];
    participants = map["participants"];
    lastMessage = map["lastmessage"];
    lastMessageSentTime = (map["lastMessageSentTime"] as Timestamp?)?.toDate();
    lastMessageSeenTime = (map["lastMessageSeenTime"] as Timestamp?)?.toDate();
    admins = List<String>.from(map["admins"] ?? []);
  }

  Map<String, dynamic> toMap() {
    return {
      "chatroomid": chatroomid,
      "groupName": groupName,
      "groupImage": groupImage,
      "participants": participants,
      "lastmessage": lastMessage,
      "lastMessageSentTime": lastMessageSentTime,
      "lastMessageSeenTime": lastMessageSeenTime,
      "admins": admins,
    };
  }

  // Add copyWith method here
  GroupChatRoomModel copyWith({
    String? chatroomid,
    String? groupName,
    String? groupImage,
    Map<String, dynamic>? participants,
    String? lastMessage,
    DateTime? lastMessageSentTime,
    DateTime? lastMessageSeenTime,
    List<String>? admins,
  }) {
    return GroupChatRoomModel(
      chatroomid: chatroomid ?? this.chatroomid,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSentTime: lastMessageSentTime ?? this.lastMessageSentTime,
      lastMessageSeenTime: lastMessageSeenTime ?? this.lastMessageSeenTime,
      admins: admins ?? this.admins,
    );
  }
}
