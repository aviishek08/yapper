import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  String? messageid;
  String? sender;
  DateTime? createdon;
  DateTime? sentTime;
  DateTime? seenTime;
  String? text;
  bool? seen;

  MessageModel({
    this.messageid,
    this.sender,
    this.createdon,
    this.sentTime,
    this.seenTime,
    this.text,
    this.seen,
  });

  MessageModel.fromMap(Map<String, dynamic> map) {
    messageid = map["messageid"];
    sender = map["sender"];
    createdon = (map["createdon"] as Timestamp).toDate();
    sentTime = (map["sentTime"] as Timestamp?)?.toDate();
    seenTime = (map["seenTime"] as Timestamp?)?.toDate();
    text = map["text"];
    seen = map["seen"];
  }

  Map<String, dynamic> toMap() {
    return {
      "messageid": messageid,
      "sender": sender,
      "createdon": createdon,
      "sentTime": sentTime,
      "seenTime": seenTime,
      "text": text,
      "seen": seen,
    };
  }
}
