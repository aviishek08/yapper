import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chatroom_model.dart';
import 'package:flutter_application_1/models/message_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatRoomPage extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatroom;
  final UserModel userModel;
  final User firebaseUser;

  const ChatRoomPage({Key? key, required this.targetUser, required this.chatroom, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  TextEditingController messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final EmojiParser _emojiParser = EmojiParser();
  File? _image;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void sendMessage({String? text, File? image, bool isEmoji = false}) async {
    String msg = text?.trim() ?? '';
    messageController.clear();

    if (image != null) {
      // Handle image upload
      String imageUrl = await _uploadImage(image);
      msg = imageUrl; // Save the URL of the image instead of text
    }

    if (msg != "") {
      MessageModel newMessage = MessageModel(
        messageid: Uuid().v1(),
        sender: widget.userModel.uid,
        createdon: DateTime.now(),
        sentTime: DateTime.now(),
        seenTime: null,
        text: isEmoji ? _emojiParser.emojify(msg) : msg, // Convert emojis
        seen: false,
      );

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatroom.chatroomid)
          .collection("messages")
          .doc(newMessage.messageid)
          .set(newMessage.toMap());

      ChatRoomModel updatedChatRoom = widget.chatroom.copyWith(
        lastMessage: msg,
        lastMessageSentTime: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatroom.chatroomid)
          .set(updatedChatRoom.toMap());

      log("Message Sent!");
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('chat_images/${Uuid().v1()}');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      log('Image upload failed: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.targetUser.profilepic != null ? NetworkImage(widget.targetUser.profilepic!) : null,
              child: widget.targetUser.profilepic == null ? Text(widget.targetUser.fullname?[0] ?? '') : null,
            ),
            SizedBox(width: 10),
            Text(widget.targetUser.fullname ?? 'No Name'),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("chatrooms")
                          .doc(widget.chatroom.chatroomid)
                          .collection("messages")
                          .orderBy("createdon", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.active) {
                          if (snapshot.hasData) {
                            QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                            return ListView.builder(
                              reverse: true,
                              itemCount: dataSnapshot.docs.length,
                              itemBuilder: (context, index) {
                                MessageModel currentMessage = MessageModel.fromMap(dataSnapshot.docs[index].data() as Map<String, dynamic>);
                                String timeSent = currentMessage.sentTime != null ? timeAgo(currentMessage.sentTime!) : "Unknown time";

                                return Row(
                                  mainAxisAlignment: (currentMessage.sender == widget.userModel.uid) ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: (currentMessage.sender == widget.userModel.uid) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.symmetric(vertical: 2),
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: (currentMessage.sender == widget.userModel.uid) ? Colors.grey : Theme.of(context).colorScheme.secondary,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              currentMessage.text != null && currentMessage.text!.startsWith('http')
                                                  ? Image.network(currentMessage.text!)
                                                  : Text(
                                                      currentMessage.text.toString(),
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                              SizedBox(height: 5),
                                              Text(
                                                "Sent: $timeSent",
                                                style: TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text("An error occurred! Please check your internet connection."),
                            );
                          } else {
                            return Center(
                              child: Text("Say hi to your new friend"),
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
                if (_showEmojiPicker)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        setState(() {
                          messageController.text += emoji.emoji;
                          _showEmojiPicker = false;
                        });
                      },
                    ),
                  ),
                Container(
                  color: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.emoji_emotions, color: Theme.of(context).colorScheme.secondary),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.image, color: Theme.of(context).colorScheme.secondary),
                        onPressed: _pickImage,
                      ),
                      Flexible(
                        child: TextField(
                          controller: messageController,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter message",
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_image != null) {
                            sendMessage(image: _image);
                            setState(() {
                              _image = null;
                            });
                          } else {
                            sendMessage(text: messageController.text);
                          }
                        },
                        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 8) {
      return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inSeconds >= 1) {
      return '${difference.inSeconds}s ago';
    } else {
      return 'Just now';

    }
  }
}
