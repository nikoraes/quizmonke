import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/multicamera/camera_file.dart';
import 'package:quizmonke/multicamera//multiple_image_camera.dart';

class PhotoScreen extends StatefulWidget {
  static String routeName = '/photo';
  const PhotoScreen({super.key});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

Future<void> onImagesCaptured(List<MediaModel> images) async {
  final newTopic = {
    "status": "uploading",
    "roles": {FirebaseAuth.instance.currentUser?.uid: "owner"}
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

  documentSnapshot.update({"status": "processing"});

  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('batchannotate')
        .call({"topicId": documentSnapshot.id, "uris": fileUris});
    final response = result.data as Map<String, dynamic>;
    print("Response: $response");
  } on FirebaseFunctionsException catch (error) {
    print("error code: ${error.code}");
    print("error details: ${error.details}");
    print("error message: ${error.message}");
  }

  /*  async {
        print("Added Data with ID: ${documentSnapshot.id}");

        // Store files in parallel
        var ids = await Future.wait<String>(images.map((e) async {
          String id = generateId();
          String filePath = 'topics/${documentSnapshot.id}/files/$id';
          Reference fileRef = storageRef.child(filePath);
          await fileRef.putData(e.blobImage);
          return id; // fileRef.getDownloadURL();
        }))

        print(ids); */

  /* .then((List<String> ids) async {
          documentSnapshot.update({"status": "processing"}); */
  // Trigger annotation function

  /* final batchAnnotatePayload = {

          } */
  /* try {
            final result = await FirebaseFunctions.instance
                .httpsCallable('batchAnnotate')
                .call({"topicId": documentSnapshot.id, "urls": urls});
            final response = result.data as String;
            print(response);
          } on FirebaseFunctionsException catch (error) {
            print(error.code);
            print(error.details);
            print(error.message);
          } */
  // }).catchError((e) => print(e));
  //})

  /* @override
      setState(() {
        images = images;
      }); */
}

class _PhotoScreenState extends State<PhotoScreen> {
  List<MediaModel> images = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ElevatedButton(
            child: const Text("Capture"),
            onPressed: () {
              // Capture images
              MultipleImageCamera.capture(context: context).then((imgs) {
                setState(() {
                  images = imgs;
                });
                onImagesCaptured(imgs);
              });
            },
          ),
          Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.file(File(images[index].file.path));
                }),
          )
        ],
      ),
    );
  }
}
