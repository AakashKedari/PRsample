import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tapioca/tapioca.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:video_player/video_player.dart';

class TapiocaTry extends StatefulWidget {
  @override
  _TapiocaTryState createState() => _TapiocaTryState();
}

class _TapiocaTryState extends State<TapiocaTry> {
  final navigatorKey = GlobalKey<NavigatorState>();
  late XFile _video;
  bool isLoading = false;
  static const EventChannel _channel =
  EventChannel('video_editor_progress');
  late StreamSubscription _streamSubscription;
  int processPercentage = 0;

  @override
  void initState() {
    super.initState();
    _enableEventReceiver();
  }

  @override
  void dispose() {
    super.dispose();
    _disableEventReceiver();
  }

  void _enableEventReceiver() {
    _streamSubscription = _channel.receiveBroadcastStream().listen(
            (dynamic event) {
          setState((){
            processPercentage = (event.toDouble()*100).round();
          });
        },
        onError: (dynamic error) {
          print('Received error: ${error.message}');
        },
        cancelOnError: true);
  }

  void _disableEventReceiver() {
    _streamSubscription.cancel();
  }
  _pickVideo() async {
    try {
      final ImagePicker _picker = ImagePicker();
      XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _video = video;
          isLoading = true;
        });
      }
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: isLoading ? Column(mainAxisSize: MainAxisSize.min,children:[

              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text("$processPercentage%", style: TextStyle(fontSize: 20),),
            ] ) : ElevatedButton(
              child: const Text("Pick a video and Edit it"),
              onPressed: () async {
                print("clicked!");
                await _pickVideo();
                var tempDir = await getTemporaryDirectory();
                final path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}result.mp4';
                print(tempDir);
                // final imageBitmap =
                // (await rootBundle.load("assets/tapioca_drink.png"))
                //     .buffer
                //     .asUint8List();
                try {
                  final tapiocaBalls = [

                    // TapiocaBall.imageOverlay(imageBitmap, 300, 300),
                    TapiocaBall.textOverlay(
                        "dolbyTesing", 100, 10, 20, const Color(0xffffc0cb)),
                  ];
                  print("will start");
                  final cup = Cup(Content(_video.path), tapiocaBalls);
                  cup.suckUp(path).then((_) async {
                    print('Hurraaaaayyyyyyyyyyyy');
                    setState(() {
                      processPercentage = 0;
                    });
                    print(path);
                    GallerySaver.saveVideo(path).then((bool? success) {
                      print(success.toString());
                    });

                      print('Inside current State');
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) =>
                              TapiVidScreen(path)),);
                      // Navigator.push(
                      //   MaterialPageRoute(builder: (context) =>
                      //       TapiVidScreen(path)),
                      // );


                    setState(() {
                      isLoading = false;
                    });
                  }).catchError((e) {
                    print('Got error: $e');

                  });
                } on PlatformException {
                  print("error!!!!");
                }
              },
            )),
      );

  }
}

class TapiVidScreen extends StatefulWidget {
  final String path;

  TapiVidScreen(this.path);

  @override
  _VideoAppState createState() => _VideoAppState(path);
}

class _VideoAppState extends State<TapiVidScreen> {
  final String path;

  _VideoAppState(this.path);

  late VideoPlayerController _controller;


  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (!_controller.value.isPlaying &&
                _controller.value.isInitialized &&
                (_controller.value.duration == _controller.value.position)) {
              _controller.initialize();
              _controller.play();
            } else {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}