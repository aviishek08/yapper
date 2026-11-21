// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/models/chatroom_model.dart';
// import 'package:flutter_application_1/models/firebase_helper.dart';
// import 'package:flutter_application_1/models/user_model.dart';
// import 'package:flutter_application_1/pages/calendar_page.dart'; // Import the Calendar Page
// import 'package:flutter_application_1/pages/chatroom_page.dart';
// import 'package:flutter_application_1/pages/group_creation_page.dart';
// import 'package:flutter_application_1/pages/groups_page.dart';
// import 'package:flutter_application_1/pages/login_page.dart';
// import 'package:flutter_application_1/pages/profile_screen.dart';
// import 'package:flutter_application_1/pages/search_page.dart';

// class HomePage extends StatefulWidget {
//   final UserModel userModel;
//   final User firebaseUser;

//   const HomePage({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   Future<void> _deleteChatForCurrentUser(String chatroomId) async {
//     try {
//       DocumentReference chatRoomRef = FirebaseFirestore.instance.collection("chatrooms").doc(chatroomId);

//       DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();
//       if (chatRoomSnapshot.exists) {
//         ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(chatRoomSnapshot.data() as Map<String, dynamic>);
        
//         // Remove current user from participants
//         chatRoomModel.participants?.remove(widget.userModel.uid);

//         // If participants map is empty, delete the entire chatroom
//         if (chatRoomModel.participants?.isEmpty ?? true) {
//           await chatRoomRef.delete();
//         } else {
//           await chatRoomRef.update(chatRoomModel.toMap());
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete chat')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text("Chat App"),
//         backgroundColor: Colors.lightBlueAccent.shade100,
//         leading: PopupMenuButton<String>(
//           onSelected: (String value) {
//             switch (value) {
//               case 'Profile':
//                 Navigator.push(context, MaterialPageRoute(builder: (context) {
//                   return ProfileScreen(userModel: widget.userModel);
//                 }));
//                 break;
//               case 'Search':
//                 Navigator.push(context, MaterialPageRoute(builder: (context) {
//                   return SearchPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
//                 }));
//                 break;
//               case 'Home':
//                 Navigator.popUntil(context, (route) => route.isFirst);
//                 break;
//               case 'Groups':
//                 Navigator.push(context, MaterialPageRoute(builder: (context) {
//                   return GroupChatsPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
//                 }));
//                 break;
//               case 'Calendar':
//                 Navigator.push(context, MaterialPageRoute(builder: (context) {
//                   return CalendarPage();
//                 }));
//                 break;
//             }
//           },
//           itemBuilder: (BuildContext context) {
//             return [
//               PopupMenuItem(
//                 value: 'Profile',
//                 child: Text('Profile'),
//               ),
//               PopupMenuItem(
//                 value: 'Search',
//                 child: Text('Search'),
//               ),
//               PopupMenuItem(
//                 value: 'Home',
//                 child: Text('Home'),
//               ),
//               PopupMenuItem(
//                 value: 'Groups',
//                 child: Text('Groups'),
//               ),
//               PopupMenuItem(
//                 value: 'Calendar',
//                 child: Text('Calendar'),
//               ),
//             ];
//           },
//           icon: Icon(Icons.menu),
//         ),
//         actions: [
//           IconButton(
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut();
//               Navigator.popUntil(context, (route) => route.isFirst);
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) {
//                     return LoginPage();
//                   },
//                 ),
//               );
//             },
//             icon: Icon(Icons.exit_to_app),
//           ),
//         ],
//       ),
//       body: SafeArea(
//   child: Container(
//     color: const Color.fromARGB(255, 150, 218, 250),
//     child: StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection("chatrooms")
//           .where("participants.${widget.userModel.uid}", isEqualTo: true)
//           .orderBy("lastMessageSentTime", descending: true) // Order by the last message sent time
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.active) {
//           if (snapshot.hasData) {
//             QuerySnapshot chatRoomSnapshot = snapshot.data as QuerySnapshot;

//             return ListView.builder(
//               itemCount: chatRoomSnapshot.docs.length,
//               itemBuilder: (context, index) {
//                 ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
//                     chatRoomSnapshot.docs[index].data() as Map<String, dynamic>);

//                 Map<String, dynamic> participants = chatRoomModel.participants ?? {};

//                 List<String> participantKeys = participants.keys.toList();
//                 participantKeys.remove(widget.userModel.uid);

//                 // Handle cases where there might be no other participants
//                 if (participantKeys.isEmpty) {
//                   return Container(); // Return an empty container if there are no participants
//                 }

//                 return FutureBuilder(
//                   future: FirebaseHelper.getUserModelById(participantKeys[0]),
//                   builder: (context, userData) {
//                     if (userData.connectionState == ConnectionState.done) {
//                       if (userData.data != null) {
//                         UserModel targetUser = userData.data as UserModel;

//                         return Card(
//                           color: Colors.white,
//                           elevation: 4,
//                           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                           child: ListTile(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) {
//                                   return ChatRoomPage(
//                                     chatroom: chatRoomModel,
//                                     firebaseUser: widget.firebaseUser,
//                                     userModel: widget.userModel,
//                                     targetUser: targetUser,
//                                   );
//                                 }),
//                               );
//                             },
//                             leading: CircleAvatar(
//                               backgroundImage: targetUser.profilepic != null && targetUser.profilepic!.isNotEmpty
//                                   ? NetworkImage(targetUser.profilepic!)
//                                   : null,
//                               child: targetUser.profilepic == null || targetUser.profilepic!.isEmpty
//                                   ? Text(
//                                       targetUser.fullname != null && targetUser.fullname!.isNotEmpty
//                                           ? targetUser.fullname![0].toUpperCase()
//                                           : '?',
//                                       style: TextStyle(color: Colors.white, fontSize: 20),
//                                     )
//                                   : null,
//                               backgroundColor: Colors.grey[400], // You can set any color here for users without profile pictures
//                             ),
//                             title: Text(targetUser.fullname.toString(), style: TextStyle(color: Colors.black87)),
//                             subtitle: (chatRoomModel.lastMessage?.isNotEmpty ?? false)
//                                 ? Text(
//                                     chatRoomModel.lastMessage.toString(),
//                                     style: TextStyle(color: Colors.grey),
//                                   )
//                                 : Text(
//                                     "Say hi to your new friend!",
//                                     style: TextStyle(
//                                       color: Colors.blueAccent,
//                                     ),
//                                   ),
//                             trailing: PopupMenuButton<String>(
//                               icon: Icon(Icons.more_vert, color: Colors.grey),
//                               onSelected: (String value) {
//                                 if (value == 'delete') {
//                                   _showDeleteConfirmationDialog(chatRoomModel.chatroomid!);
//                                 }
//                               },
//                               itemBuilder: (BuildContext context) {
//                                 return [
//                                   PopupMenuItem(
//                                     value: 'delete',
//                                     child: Text('Delete'),
//                                   ),
//                                 ];
//                               },
//                             ),
//                           ),
//                         );
//                       } else {
//                         return Container(); // Handle the case where userData is null
//                       }
//                     } else {
//                       return Center(
//                         child: CircularProgressIndicator(),
//                       );
//                     }
//                   },
//                 );
//               },
//             );
//           } else if (snapshot.hasError) {
//             return Center(
//               child: Text(snapshot.error.toString()),
//             );
//           } else {
//             return Center(
//               child: Text("No Chats"),
//             );
//           }
//         } else {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//       },
//     ),
//   ),
// ),

//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) {
//                 return GroupCreationPage(userModel: widget.userModel);
//               },
//             ),
//           );
//         },
//         backgroundColor: Colors.lightBlueAccent,
//         child: Icon(Icons.group_add),
//       ),
//     );
//   }

//   void _showDeleteConfirmationDialog(String chatroomId) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Delete Chat'),
//           content: Text('Are you sure you want to delete this chat?'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 _deleteChatForCurrentUser(chatroomId);
//                 Navigator.of(context).pop();
//               },
//               child: Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chatroom_model.dart';
import 'package:flutter_application_1/models/firebase_helper.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/pages/calendar_page.dart'; 
import 'package:flutter_application_1/pages/chatroom_page.dart';
import 'package:flutter_application_1/pages/group_creation_page.dart';
import 'package:flutter_application_1/pages/groups_page.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:flutter_application_1/pages/profile_screen.dart';
import 'package:flutter_application_1/pages/search_page.dart';

class HomePage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const HomePage({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _deleteChatForCurrentUser(String chatroomId) async {
    try {
      DocumentReference chatRoomRef = FirebaseFirestore.instance.collection("chatrooms").doc(chatroomId);

      DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();
      if (chatRoomSnapshot.exists) {
        ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(chatRoomSnapshot.data() as Map<String, dynamic>);
        
        // Remove current user from participants
        chatRoomModel.participants?.remove(widget.userModel.uid);

        // If participants map is empty, delete the entire chatroom
        if (chatRoomModel.participants?.isEmpty ?? true) {
          await chatRoomRef.delete();
        } else {
          await chatRoomRef.update(chatRoomModel.toMap());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete chat')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Chat App"),
        backgroundColor: Colors.lightBlueAccent.shade100,
        leading: PopupMenuButton<String>(
          onSelected: (String value) {
            switch (value) {
              case 'Profile':
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ProfileScreen(userModel: widget.userModel);
                }));
                break;
              case 'Search':
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return SearchPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
                }));
                break;
              case 'Home':
                Navigator.popUntil(context, (route) => route.isFirst);
                break;
              case 'Groups':
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return GroupChatsPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
                }));
                break;
              case 'Calendar':
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CalendarPage();
                }));
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'Profile',
                child: Text('Profile'),
              ),
              PopupMenuItem(
                value: 'Search',
                child: Text('Search'),
              ),
              PopupMenuItem(
                value: 'Home',
                child: Text('Home'),
              ),
              PopupMenuItem(
                value: 'Groups',
                child: Text('Groups'),
              ),
              PopupMenuItem(
                value: 'Calendar',
                child: Text('Calendar'),
              ),
            ];
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            },
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: const Color.fromARGB(255, 150, 218, 250),
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection("chatrooms").where("participants.${widget.userModel.uid}", isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  QuerySnapshot chatRoomSnapshot = snapshot.data as QuerySnapshot;

                  return ListView.builder(
                    itemCount: chatRoomSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
                          chatRoomSnapshot.docs[index].data() as Map<String, dynamic>);

                      Map<String, dynamic> participants = chatRoomModel.participants ?? {};

                      List<String> participantKeys = participants.keys.toList();
                      participantKeys.remove(widget.userModel.uid);

                      
                      if (participantKeys.isEmpty) {
                        return Container(); 
                      }

                      return FutureBuilder(
                        future: FirebaseHelper.getUserModelById(participantKeys[0]),
                        builder: (context, userData) {
                          if (userData.connectionState == ConnectionState.done) {
                            if (userData.data != null) {
                              UserModel targetUser = userData.data as UserModel;

                              return Card(
                                color: Colors.white,
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) {
                                        return ChatRoomPage(
                                          chatroom: chatRoomModel,
                                          firebaseUser: widget.firebaseUser,
                                          userModel: widget.userModel,
                                          targetUser: targetUser,
                                        );
                                      }),
                                    );
                                  },
                                  leading: CircleAvatar(
  backgroundImage: targetUser.profilepic != null && targetUser.profilepic!.isNotEmpty
      ? NetworkImage(targetUser.profilepic!)
      : null,
  child: targetUser.profilepic == null || targetUser.profilepic!.isEmpty
      ? Text(
          targetUser.fullname != null && targetUser.fullname!.isNotEmpty
              ? targetUser.fullname![0].toUpperCase()
              : '?',
          style: TextStyle(color: Colors.white, fontSize: 20),
        )
      : null,
  backgroundColor: Colors.grey[400], // You can set any color here for users without profile pictures
),

                                  title: Text(targetUser.fullname.toString(), style: TextStyle(color: Colors.black87)),
                                  subtitle: (chatRoomModel.lastMessage?.isNotEmpty ?? false)
                                      ? Text(
                                          chatRoomModel.lastMessage.toString(),
                                          style: TextStyle(color: Colors.grey),
                                        )
                                      : Text(
                                          "Say hi to your new friend!",
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                  trailing: PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: Colors.grey),
                                    onSelected: (String value) {
                                      if (value == 'delete') {
                                        _showDeleteConfirmationDialog(chatRoomModel.chatroomid!);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ];
                                    },
                                  ),
                                ),
                              );
                            } else {
                              return Container(); 
                            }
                          } else {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      );
                    },
                  );

                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                } else {
                  return Center(
                    child: Text("No Chats"),
                  );
                }
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return GroupCreationPage(userModel: widget.userModel);
              },
            ),
          );
        },
        backgroundColor: Colors.lightBlueAccent,
        child: Icon(Icons.group_add),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String chatroomId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Chat'),
          content: Text('Are you sure you want to delete this chat?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteChatForCurrentUser(chatroomId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}