import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chatroom_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/pages/chatroom_page.dart';
import 'package:uuid/uuid.dart';

class SearchPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const SearchPage({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  Stream<QuerySnapshot>? searchResultsStream;
  Timer? debounce;

  Future<ChatRoomModel?> getChatroomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("chatrooms").where("participants.${widget.userModel.uid}", isEqualTo: true).where("participants.${targetUser.uid}", isEqualTo: true).get();

    if (snapshot.docs.isNotEmpty) {
      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChatroom = ChatRoomModel.fromMap(docData as Map<String, dynamic>);

      chatRoom = existingChatroom;
    } else {
      ChatRoomModel newChatroom = ChatRoomModel(
        chatroomid: Uuid().v1(),
        lastMessage: "",
        participants: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );

      await FirebaseFirestore.instance.collection("chatrooms").doc(newChatroom.chatroomid).set(newChatroom.toMap());

      chatRoom = newChatroom;

      log("New Chatroom Created!");
    }

    return chatRoom;
  }

  void _searchUsers(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchResultsStream = FirebaseFirestore.instance
            .collection("users")
            .where("email", isGreaterThanOrEqualTo: query)
            .where("email", isLessThan: query + 'z')
            .where("email", isNotEqualTo: widget.userModel.email)
            .snapshots();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      _searchUsers(searchController.text.trim());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: searchResultsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("An error occurred!"));
                    } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No results found!"));
                    } else {
                      List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> userMap = docs[index].data() as Map<String, dynamic>;
                          UserModel searchedUser = UserModel.fromMap(userMap);

                          return ListTile(
                            onTap: () async {
                              ChatRoomModel? chatroomModel = await getChatroomModel(searchedUser);

                              if (chatroomModel != null) {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) {
                                    return ChatRoomPage(
                                      targetUser: searchedUser,
                                      userModel: widget.userModel,
                                      firebaseUser: widget.firebaseUser,
                                      chatroom: chatroomModel,
                                    );
                                  }
                                ));
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: searchedUser.fullname != null && searchedUser.fullname!.isNotEmpty
                                  ? Text(
                                      searchedUser.fullname![0].toUpperCase(),
                                      style: TextStyle(color: Colors.black),
                                    )
                                  : Icon(Icons.person, color: Colors.black),
                              backgroundImage: searchedUser.profilepic != null && searchedUser.profilepic!.isNotEmpty
                                  ? NetworkImage(searchedUser.profilepic!)
                                  : null,
                            ),
                            title: Text(searchedUser.fullname ?? 'No Name'),
                            subtitle: Text(searchedUser.email ?? 'No Email'),
                            trailing: Icon(Icons.keyboard_arrow_right),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
