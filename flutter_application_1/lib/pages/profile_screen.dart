import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel userModel;

  const ProfileScreen({Key? key, required this.userModel}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userModel.fullname ?? '';
    _emailController.text = widget.userModel.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 20,
      );

      if (croppedImage != null) {
        setState(() {
          _imageFile = File(croppedImage.path);
        });
      }
    }
  }

  Future<void> _uploadImage(String uid) async {
    if (_imageFile == null) return;

    UploadTask uploadTask = FirebaseStorage.instance
        .ref("profilepictures")
        .child(uid)
        .putFile(_imageFile!);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    setState(() {
      widget.userModel.profilepic = downloadUrl;
    });
  }

  void _saveProfile() async {
    String uid = widget.userModel.uid ?? '';
    String fullname = _nameController.text.trim();
    String email = _emailController.text.trim();

    if (fullname.isNotEmpty && email.isNotEmpty) {
      await _uploadImage(uid);

      UserModel updatedUser = UserModel(
        uid: uid,
        fullname: fullname,
        email: email,
        profilepic: widget.userModel.profilepic,
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update(updatedUser.toMap());

      setState(() {
        widget.userModel.fullname = fullname;
        widget.userModel.email = email;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Profile updated successfully!"),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Name and Email cannot be empty."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _selectImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : NetworkImage(widget.userModel.profilepic ?? '') as ImageProvider,
                  child: _imageFile == null && widget.userModel.profilepic == null
                      ? Text(
                          widget.userModel.fullname != null && widget.userModel.fullname!.isNotEmpty
                              ? widget.userModel.fullname![0].toUpperCase()
                              : '?',
                          style: TextStyle(color: Colors.white, fontSize: 50),
                        )
                      : null,
                  backgroundColor: Colors.grey[400], // Default background color for avatars
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text("Save Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
