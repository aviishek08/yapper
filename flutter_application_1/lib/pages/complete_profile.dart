import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfile extends StatefulWidget {
  final UserModel? userModel;
  final User? firebaseUser;

  const CompleteProfile({super.key, this.userModel, this.firebaseUser});

  @override
  State<CompleteProfile> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {
  File? imageFile;
  Uint8List? webImage; // For storing the selected image in web
  TextEditingController fullNameController = TextEditingController();
  String? profilePicUrl;

  @override
  void initState() {
    super.initState();
    fullNameController.addListener(_updateProfilePic);
  }

  void _updateProfilePic() {
    final fullName = fullNameController.text.trim();
    if (fullName.isNotEmpty) {
      final firstLetter = fullName[0].toUpperCase();
      setState(() {
        profilePicUrl = null; // Clear any previous image
      });
    } else {
      setState(() {
        profilePicUrl = null;
      });
    }
  }

  void selectImage(ImageSource source) async {
    try {
      XFile? pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile != null) {
        cropImage(pickedFile);
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void cropImage(XFile file) async {
    try {
      CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 20,
        uiSettings: [
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedImage != null) {
        setState(() {
          imageFile = File(croppedImage.path);
          webImage = null; // Clear web image if using a file
        });
      } else {
        print("Image cropping canceled");
      }
    } catch (e) {
      print("Error cropping image: $e");
    }
  }

  void showPhotoOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Upload Profile Picture"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  selectImage(ImageSource.gallery);
                },
                leading: Icon(Icons.photo_album),
                title: Text("Select from Gallery"),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  selectImage(ImageSource.camera);
                },
                leading: Icon(Icons.camera_alt),
                title: Text("Take a photo"),
              ),
            ],
          ),
        );
      },
    );
  }

  void checkValues() {
    String fullname = fullNameController.text.trim();

    if (fullname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all the fields")),
      );
    } else {
      uploadData();
    }
  }

  void uploadData() async {
    String? imageUrl;

    // Only upload the image if one is selected
    if (imageFile != null || webImage != null) {
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = FirebaseStorage.instance
            .ref("profilepictures")
            .child(widget.userModel!.uid.toString())
            .putData(webImage!);
      } else {
        uploadTask = FirebaseStorage.instance
            .ref("profilepictures")
            .child(widget.userModel!.uid.toString())
            .putFile(imageFile!);
      }

      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    String fullname = fullNameController.text.trim();

    widget.userModel!.fullname = fullname;

    // Only update the profile picture if an image is provided
    if (imageUrl != null) {
      widget.userModel!.profilepic = imageUrl;
    } else if (profilePicUrl != null) {
      widget.userModel!.profilepic = profilePicUrl; // Use default profile pic if no image
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userModel!.uid)
        .set(widget.userModel!.toMap())
        .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully!")),
      );
      print("Data uploaded!");

      // Navigate to the home page with the required arguments
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            userModel: widget.userModel!,
            firebaseUser: widget.firebaseUser!,
          ),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $error")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("Complete Profile"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: ListView(
            children: [
              SizedBox(height: 20),
              CupertinoButton(
                onPressed: () {
                  showPhotoOptions();
                },
                padding: EdgeInsets.all(0),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: kIsWeb && webImage != null
                      ? MemoryImage(webImage!)
                      : imageFile != null
                          ? FileImage(imageFile!)
                          : (profilePicUrl != null
                              ? NetworkImage(profilePicUrl!)
                              : null),
                  child: (imageFile == null && webImage == null && profilePicUrl == null)
                      ? Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                ),
              ),
              SizedBox(height: 20),
              CupertinoButton(
                onPressed: () {
                  checkValues();
                },
                color: Theme.of(context).colorScheme.secondary,
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
