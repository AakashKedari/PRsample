import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
// import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffprobe_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/screens/saved_edited_reels_screen.dart';
import 'package:prsample/screens/images_preview_screen.dart';
import 'package:prsample/screens/video_editor_screen.dart';

class SelectImageScreen extends StatefulWidget {
  const SelectImageScreen({super.key});

  @override
  State<SelectImageScreen> createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<List<Uint8List>> convertXFileListToUint8List(List<XFile> xFiles) async {
    List<Uint8List> uint8Lists = [];

    for (var xFile in xFiles) {
      List<int> bytes = await xFile.readAsBytes();
      Uint8List uint8List = Uint8List.fromList(bytes);
      uint8Lists.add(uint8List);
    }

    return uint8Lists;
  }


  void _pickVideo() async {
    Directory third = await getApplicationSupportDirectory();
    log(third.path);
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

    if (mounted && file != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => VideoEditor(file: File(file.path),collageFlag: false,),
        ),
      );
    }
  }

  List<XFile> selectedImagesPaths = [];
  late Directory directory;
  void pickImages() async {
    directory = await getTemporaryDirectory();
    isLoading = true;
    setState(() {});

    try {
      ImagePicker imagePicker = ImagePicker();
      selectedImagesPaths = await imagePicker.pickMultiImage();

      if (selectedImagesPaths.isNotEmpty && mounted) {
        List<Uint8List> uint8Lists = await convertXFileListToUint8List(selectedImagesPaths);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ImageTimer(
                      images: uint8Lists,
                  ximages: selectedImagesPaths,
                    )));
      } else if (selectedImagesPaths.isEmpty) {
        setState(() {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Nothing Selected")));
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error picking images: $e");
    }
  }

  void videoInfo() {
    FFprobeKit.getMediaInformationAsync(
        '/storage/emulated/0/unico Connect/VID-20230204-WA0004.mp4',
        (session) async {
      final information = (session).getMediaInformation()!;
      var logger = Logger();
      logger.d(information.getAllProperties());
      setState(() {});
    });
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: !isLoading
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Hello...',
                        style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Lets Start Creating ',
                      style: TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: pickImages,
                          child: const Text("Image Collage"),
                        ),
                        ElevatedButton(
                          onPressed: _pickVideo,
                          child: const Text("Edit a Video"),
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const CachedVideos()));
                            },
                            child: const Text("Saved Edits"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Creating Video"),
                    SizedBox(
                      height: 10,
                    ),
                    CircularProgressIndicator()
                  ],
                ),
              ),
      ),
    );
  }
}
