import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chatroom_model.dart';
import 'package:flutter_application_1/models/group_chat_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/pages/group_chat_page.dart';
import 'package:flutter_application_1/pages/group_creation_page.dart';

class GroupChatsPage extends StatelessWidget {
  final UserModel userModel;
  final User firebaseUser;

  const GroupChatsPage({required this.userModel, required this.firebaseUser, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupCreationPage(userModel: userModel),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('groupchatrooms')
            .where('participants.${userModel.uid}', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              QuerySnapshot groupChatSnapshot = snapshot.data as QuerySnapshot;

              return ListView.builder(
                itemCount: groupChatSnapshot.docs.length,
                itemBuilder: (context, index) {
                  GroupChatRoomModel groupChatRoom = GroupChatRoomModel.fromMap(
                    groupChatSnapshot.docs[index].data() as Map<String, dynamic>,
                  );

                  return ListTile(
                    title: Text(groupChatRoom.groupName ?? 'Group Chat'),
                    subtitle: Text(groupChatRoom.lastMessage ?? ''),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        groupChatRoom.groupImage ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupChatPage(
                            chatRoomModel: groupChatRoom,
                            userModel: userModel,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Center(child: Text('No Group Chats'));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
