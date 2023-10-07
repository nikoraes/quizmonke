import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/home/topics_list.dart';
import 'package:quizmonke/multicamera/camera_file.dart';
import 'package:quizmonke/multicamera/multiple_image_camera.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = '/';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is signed out, navigate to '/sign-in'
        Navigator.pushReplacementNamed(context, '/sign-in');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          leadingWidth: 48,
          leading: Image.asset('assets/logo.png'),
          title: const Text('QuizMonke'),
          actions: const <Widget>[HomeAppBarMenu()]),
      body: const TopicsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a file picker on web
          if (kIsWeb) {
            FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['jpg', 'jpeg'],
            ).then((result) {
              if (result != null) {
                List<MediaModel> imageList = <MediaModel>[];
                for (int i = 0; i < result.files.length; i++) {
                  File file = File(result.files[i].name);
                  imageList.add(
                    MediaModel.blob(file, "", file.readAsBytesSync()),
                  );
                }
                onImagesCaptured(imageList);
              }
            });
          } else {
            // Use camera in app
            MultipleImageCamera.capture(context: context).then((imgs) {
              onImagesCaptured(imgs);
            });
          }
        },
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}

class HomeAppBarMenu extends StatelessWidget {
  const HomeAppBarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
          tooltip: 'Show menu',
        );
      },
      menuChildren: [
        MenuItemButton(
          child: const Text('Account'),
          onPressed: () async {
            Navigator.pushNamed(context, '/profile');
            // await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    );
  }
}

Future<void> onImagesCaptured(List<MediaModel> images) async {
  if (images.isEmpty) return;

  final newTopic = {
    "extractStatus": "uploading",
    "roles": {FirebaseAuth.instance.currentUser?.uid: "owner"},
    "timestamp": Timestamp.now()
  };
  // Store empty topic in database
  DocumentReference<Map<String, dynamic>> documentSnapshot =
      await FirebaseFirestore.instance
          .collection("topics")
          .add(newTopic)
          .then((value) => value);

  print(
      "Added new doc with ID: ${documentSnapshot.id} (${documentSnapshot.path})");

  Future<String> uploadImage(MediaModel e) async {
    String id = "IMG_${DateTime.now().toUtc().toIso8601String()}";
    String filePath = 'topics/${documentSnapshot.id}/files/$id';
    Reference fileRef = FirebaseStorage.instance.ref().child(filePath);
    await fileRef.putData(e.blobImage);
    return 'gs://${fileRef.storage.bucket}/${fileRef.fullPath}';
  }

  List<String> fileUris = await Future.wait<String>(images.map(uploadImage));

  print("File URIs: ${fileUris.toString()}");

  documentSnapshot.update({"extractStatus": "processing"});

  try {
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('batch_annotate_fn')
        .call({"topicId": documentSnapshot.id, "uris": fileUris});
    final response = result.data as Map<String, dynamic>;
    print("Response: $response");
  } on FirebaseFunctionsException catch (error) {
    documentSnapshot.update({
      "extractStatus": "${error.code} - ${error.message} - ${error.details}"
    });

    print("error code: ${error.code}");
    print("error details: ${error.details}");
    print("error message: ${error.message}");
  }
}
