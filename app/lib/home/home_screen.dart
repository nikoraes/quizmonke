import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/home/topics_list.dart';
import 'package:quizmonke/multicamera/camera_file.dart';
import 'package:quizmonke/multicamera/multiple_image_camera.dart';
import 'package:quizmonke/services/process_images.dart';

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
        );
      },
      menuChildren: [
        MenuItemButton(
          child: Text(AppLocalizations.of(context)!.account),
          onPressed: () async {
            Navigator.pushNamed(context, '/profile');
            // await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    );
  }
}
