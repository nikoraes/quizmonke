import 'dart:async';
import 'dart:io';
import "package:flutter/material.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import "package:camera/camera.dart";
import 'package:flutter/services.dart';
import 'package:quizmonke/multicamera/image_preview.dart';

class CameraFile extends StatefulWidget {
  const CameraFile({super.key});

  @override
  State<CameraFile> createState() => _CameraFileState();
}

class _CameraFileState extends State<CameraFile> with TickerProviderStateMixin {
  double zoom = 0.0;
  double _scaleFactor = 1.0;
  double scale = 1.0;
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  List<XFile> imageFiles = [];
  List<MediaModel> imageList = <MediaModel>[];
  late int _currIndex;
  /* late Animation<double> animation;
  late AnimationController _animationController;
  late AnimationController controller;
  late Animation<double> scaleAnimation; */

  addImages(XFile image) {
    setState(() {
      imageFiles.add(image);
      /* _animationController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1500));
      animation = Tween<double>(begin: 400, end: 1).animate(scaleAnimation =
          CurvedAnimation(
              parent: _animationController, curve: Curves.elasticOut))
        ..addListener(() {});
      _animationController.forward(); */
    });
  }

  removeImage() {
    setState(() {
      imageFiles.removeLast();
    });
  }

  Widget _doneButton() {
    return Container(
      height: 70,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white38,
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.done,
          style: const TextStyle(
              fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    // ignore: unnecessary_null_comparison
    if (_cameras != null) {
      _controller = CameraController(_cameras[0], ResolutionPreset.ultraHigh,
          enableAudio: false);
      _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    } else {}
  }

  @override
  void initState() {
    _initCamera();
    _currIndex = 0;

    super.initState();
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onScaleStart: (details) {
        zoom = _scaleFactor;
      },
      onScaleUpdate: (details) {
        _scaleFactor = zoom * details.scale;
        _controller!.setZoomLevel(_scaleFactor);
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller!),
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              shrinkWrap: true,
              itemCount: imageFiles.length,
              itemBuilder: ((context, index) {
                return Row(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.bottomLeft,
                      // ignore: unnecessary_null_comparison
                      child: imageFiles[index] == null
                          ? const Text("No image captured")
                          : imageFiles.length - 1 == index
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            ImagePreviewView(
                                          File(imageFiles[index].path),
                                          "",
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        File(
                                          imageFiles[index].path,
                                        ),
                                        height: 90,
                                        width: 60,
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              removeImage();
                                            });
                                          },
                                          child: const CloseButtonIcon(),
                                          /* SvgPicture.asset(
                                                  "assets/icons/close_orange.svg"), */
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            ImagePreviewView(
                                          File(imageFiles[index].path),
                                          "",
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.file(
                                    File(
                                      imageFiles[index].path,
                                    ),
                                    height: 90,
                                    width: 60,
                                  ),
                                ),
                    )
                  ],
                );
              }),
              scrollDirection: Axis.horizontal,
            ),
            Positioned(
              left: MediaQuery.of(context).orientation == Orientation.portrait
                  ? 0
                  : null,
              bottom: MediaQuery.of(context).orientation == Orientation.portrait
                  ? 0
                  : MediaQuery.of(context).size.height / 2.5,
              right: 0,
              child: Column(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.white,
                        // Limit to max 5 images
                        onPressed: imageFiles.length <= 5
                            ? () {
                                _currIndex = _currIndex == 0 ? 1 : 0;
                                takePicture();
                              }
                            : null,
                        child: const Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  takePicture() async {
    if (_controller!.value.isTakingPicture) {
      return null;
    }
    try {
      final image = await _controller!.takePicture();
      setState(() {
        addImages(image);
        HapticFeedback.lightImpact();
      });
    } on CameraException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      if (!_controller!.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          imageFiles.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      for (int i = 0; i < imageFiles.length; i++) {
                        File file = File(imageFiles[i].path);
                        imageList.add(
                          MediaModel.blob(file, "", file.readAsBytesSync()),
                        );
                      }
                      Navigator.pop(context, imageList);
                    },
                    child: Text(AppLocalizations.of(context)!.done),
                  ),
                )
              : const SizedBox()
        ],
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
        backgroundColor:
            Theme.of(context).colorScheme.background.withOpacity(0.0),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      extendBody: true,
      body: _buildCameraPreview(),
      /* floatingActionButton: imageFiles.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                for (int i = 0; i < imageFiles.length; i++) {
                  File file = File(imageFiles[i].path);
                  imageList
                      .add(MediaModel.blob(file, "", file.readAsBytesSync()));
                }
                Navigator.pop(context, imageList);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _doneButton(),
              ))
          : const SizedBox(), */
    );
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    } /* else {
      _animationController.dispose();
    } */

    super.dispose();
  }
}

class MediaModel {
  File file;
  String filePath;
  Uint8List blobImage;
  MediaModel.blob(this.file, this.filePath, this.blobImage);
}
