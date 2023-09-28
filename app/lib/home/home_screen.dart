import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/home/topics_list.dart';
import 'package:quizmonke/multicamera/camera_file.dart';
import 'package:quizmonke/multicamera/multiple_image_camera.dart';

class MyHomePage extends StatefulWidget {
  static String routeName = '/';
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text('QuizMonke'),
      ),
      body: const TopicsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          MultipleImageCamera.capture(context: context).then((imgs) {
            onImagesCaptured(imgs);
          });
        },
        label: const Text('New'),
        icon: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Future<void> onImagesCaptured(List<MediaModel> images) async {
  final newTopic = {
    "extractStatus": "uploading",
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

  documentSnapshot.update({"extractStatus": "processing"});

  try {
    final result = await FirebaseFunctions.instance
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
