import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:quizmonke/multicamera/camera_file.dart';

Future<void> onImagesCaptured(List<MediaModel> images) async {
  if (images.isEmpty) return;

  final newTopic = {
    "status": "uploading",
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
    /* documentSnapshot.update({
      "extractStatus":
          "error: ${error.code} - ${error.message} - ${error.details}"
    }); */

    print("error code: ${error.code}");
    print("error details: ${error.details}");
    print("error message: ${error.message}");
  }
}
