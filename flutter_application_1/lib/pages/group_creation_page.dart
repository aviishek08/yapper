import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/group_chat_model.dart';
import 'package:flutter_application_1/models/user_model.dart';

class GroupCreationPage extends StatefulWidget {
  final UserModel userModel;

  GroupCreationPage({required this.userModel});

  @override
  _GroupCreationPageState createState() => _GroupCreationPageState();
}

class _GroupCreationPageState extends State<GroupCreationPage> {
  TextEditingController groupNameController = TextEditingController();
  List<UserModel> selectedUsers = [];
  List<UserModel> allUsers = [];

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  @override
  void dispose() {
    groupNameController.dispose(); 
    super.dispose();
  }

  void fetchAllUsers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      allUsers = snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      allUsers.removeWhere((user) => user.uid == widget.userModel.uid); // Remove the current user from the list
    });
  }

  void createGroupChat() async {
    if (selectedUsers.isNotEmpty && groupNameController.text.trim().isNotEmpty) {
      DocumentReference chatRoomRef = FirebaseFirestore.instance.collection('groupchatrooms').doc();

      Map<String, dynamic> participants = {
        widget.userModel.uid!: true,
        for (var user in selectedUsers) user.uid!: true,
      };

      GroupChatRoomModel newGroupChatRoom = GroupChatRoomModel(
        chatroomid: chatRoomRef.id,
        groupName: groupNameController.text.trim(),
        participants: participants,
        admins: [widget.userModel.uid!],
      );

      await chatRoomRef.set(newGroupChatRoom.toMap());

      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a group name and select at least one user.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: createGroupChat,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  UserModel user = allUsers[index];
                  bool isSelected = selectedUsers.contains(user);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.profilepic ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(user.fullname ?? 'No Name'),
                    subtitle: Text(user.email ?? 'No Email'),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedUsers.add(user);
                          } else {
                            selectedUsers.remove(user);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
