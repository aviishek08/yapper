import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/group_chat_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/firebase_helper.dart';

class GroupChatPage extends StatefulWidget {
  final GroupChatRoomModel chatRoomModel;
  final UserModel userModel;

  GroupChatPage({required this.chatRoomModel, required this.userModel});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  TextEditingController messageController = TextEditingController();
  List<UserModel> participants = [];
  late String groupCreatorId;

  @override
  void initState() {
    super.initState();
    fetchParticipants();
    groupCreatorId = widget.chatRoomModel.admins?.first ?? '';
  }

  void fetchParticipants() async {
    List<UserModel> fetchedParticipants = [];

    // Include the current user in the participant list
    fetchedParticipants.add(widget.userModel);

    for (String uid in widget.chatRoomModel.participants!.keys) {
      if (uid != widget.userModel.uid) {
        UserModel? user = await FirebaseHelper.getUserModelById(uid);
        if (user != null) {
          fetchedParticipants.add(user);
        }
      }
    }
    setState(() {
      participants = fetchedParticipants;
    });
  }

  void sendMessage() async {
    String message = messageController.text.trim();
    if (message.isNotEmpty) {
      DocumentReference messageRef = FirebaseFirestore.instance
          .collection('groupchatrooms')
          .doc(widget.chatRoomModel.chatroomid)
          .collection('messages')
          .doc();

      Map<String, dynamic> messageData = {
        'sender': widget.userModel.uid,
        'senderName': widget.userModel.fullname,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await messageRef.set(messageData);
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomModel.groupName ?? 'Group Chat'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.group),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: Text('Participants'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  UserModel participant = participants[index];
                  bool isAdmin = participant.uid == groupCreatorId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(participant.profilepic ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(participant.fullname ?? 'No Name'),
                    subtitle: Text(participant.email ?? 'No Email'),
                    trailing: isAdmin ? Chip(label: Text('Admin')) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('groupchatrooms')
                  .doc(widget.chatRoomModel.chatroomid)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    QuerySnapshot messagesSnapshot = snapshot.data as QuerySnapshot;

                    if (messagesSnapshot.docs.isEmpty) {
                      return Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      reverse: true,
                      itemCount: messagesSnapshot.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> messageData = messagesSnapshot.docs[index].data() as Map<String, dynamic>;
                        bool isCurrentUser = messageData['sender'] == widget.userModel.uid;

                        return Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.lightBlueAccent : Colors.lightGreenAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageData['senderName'] ?? 'Unknown Sender',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentUser ? Colors.white : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  messageData['message'],
                                  style: TextStyle(
                                    color: isCurrentUser ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    return Center(child: Text('No messages yet'));
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
