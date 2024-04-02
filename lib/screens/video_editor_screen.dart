import 'dart:developer';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffprobe_session.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/filters.dart';
import 'package:prsample/screens/selectfiles.dart';
import 'package:video_editor/video_editor.dart';

class VideoEditor extends StatefulWidget {
  const VideoEditor({super.key, required this.file});

  final File file;

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;
  TextEditingController imgVidController = TextEditingController();

  late VideoEditorController _controller = VideoEditorController.file(
    widget.file,
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 20),
  );
  late String toSavePath;
  bool filterLoading = false;
  bool audioLoading = false;
  double vidHeight=0.0;
  double vidWidth = 0.0;
  late double aspectratio;

  @override
  void initState() {
    toSavePath = widget.file.path;
    super.initState();
    FFprobeKit.getMediaInformationAsync(
        toSavePath,
            (session) async {
          final information = (session).getMediaInformation()!;
          int h =  information.getAllProperties()!['streams'][0]['height'];
          vidHeight = h.toDouble();
          int w = information.getAllProperties()!['streams'][0]['width'];
          vidWidth = w.toDouble();
          double bigValue = vidWidth/vidHeight; // Example double value
           aspectratio = double.parse(bigValue.toStringAsFixed(2));

          log("height : ${information.getAllProperties()!['streams'][0]['width'].toString()}");
          log("width : ${information.getAllProperties()!['streams'][0]['height'].toString()}");


        }).then((value) {
      Future.delayed(const Duration(seconds: 2)).then((value) {
        _controller
            .initialize(aspectRatio: aspectratio)
            .then((_) => setState(() {}))
            .catchError((error) {
          // handle minimum duration bigger than video duration error
          Navigator.pop(context);
        }, test: (e) => e is VideoMinDurationError);
      });

    });

  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    // ExportService.dispose();
    super.dispose();
  }

  Future<void> pickAudioFile() async {
    Directory directory = await getTemporaryDirectory();
    setState(() {
      audioLoading = true;
    });
    try {
      FilePickerResult? pickedFiles = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.audio);

      if (pickedFiles != null) {
        // Get the first selected file
        final file = File(pickedFiles.files.first.path!);

        // Define a new file path in the cache directory
        final String newFilePath =
            '${directory.path}/copied_audio.mp3'; // You can change the file extension as per your audio file type

        // Copy the file to the cache directory
        await file.copy(newFilePath);

        // Below command to replace a video's sound
        String outputPath =
            '${directory.path}/temporary.mp4';
        String commandtoExecute =
            // '-i ${widget.file.path} -i $newFilePath -c copy $outputPath';
            '-i ${widget.file.path} -i $newFilePath -map 0:v -map 1:a -c:v copy -c:a aac $outputPath';

        // In case if the User decides to save the temporary cache created video file,
        //WE copy the temporary output Path to the Device's toSavePath...
        toSavePath = outputPath;
        await FFmpegKit.execute(commandtoExecute).then((session) async {
          ReturnCode? variable = await session.getReturnCode();

          if (variable?.isValueSuccess() == true) {

            print('Video conversion successful');
            setState(() {
              audioLoading = false;
              _controller = VideoEditorController.file(File(outputPath),
                  minDuration: const Duration(seconds: 1),
                  maxDuration: const Duration(seconds: 20));
              _controller
                  .initialize(aspectRatio: aspectratio)
                  .then((_) => setState(() {}));
            });
          } else {
            setState(() {
              audioLoading = false;
            });
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Operation Failed!!!')));
            final List<Log> info = await session.getAllLogs();
            for (int i = 0; i < info.length; i++) {
              print(info[i].getMessage());
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        audioLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error Loading File')));
      print('Error picking files: $e');
    }
  }

  Future<void> applyTextOnVideo() async {

    Directory directory = await getTemporaryDirectory();
    String tempTextOverlayPath = '${directory.path}/${DateTime.now().microsecond.toString()}.mp4';
    String command = ' -i $toSavePath -vf "drawtext=text='"${imgVidController.value.text.toString()}"':fontcolor=purple:fontsize=50:x=200:y=200" -c:a copy $tempTextOverlayPath';
    FFmpegKit.execute(command).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        toSavePath = tempTextOverlayPath;
        print('Video conversion successful');

      setState(() {
              _controller = VideoEditorController.file(File(tempTextOverlayPath),
                  minDuration: const Duration(seconds: 1),
                  maxDuration: const Duration(seconds: 20));
              _controller
                  .initialize(aspectRatio: aspectratio)
                  .then((_) => setState(() {}));
            }); }
      else {
        setState(() {

        });
        final List<Log> info = await session.getAllLogs();
        for (int i = 0; i < info.length; i++) {
          print(info[i].getMessage());
        }
      }
    });

    // var tempDir = await getTemporaryDirectory();
    // final path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}result.mp4';
    // try {
    //   final tapiocaBalls = [
    //     TapiocaBall.textOverlay(
    //         "testing", 100, 10, 100, const Color(0xffffc0cb)),
    //   ];
    //   final cup = Cup(Content(toSavePath), tapiocaBalls);
    //   cup.suckUp(path).then((_) async {
    //     GallerySaver.saveVideo(path).then((bool? success) {
    //       print('Hurraaaaayyyyyyyyyyyy${success.toString()}');
    //     });
    //     setState(() {
    //       _controller = VideoEditorController.file(File(path),
    //           minDuration: const Duration(seconds: 1),
    //           maxDuration: const Duration(seconds: 20));
    //       _controller
    //           .initialize(aspectRatio: 16 / 9)
    //           .then((_) => setState(() {}));
    //     });
    //   });
    // }
    // catch(e){
    //   print("&&&&&&&&&&&&###############@@@@@@@${e.toString()}");
    // }
  }
  /// Export the video as a GIF image
  Future<void> exportGif() async {
    final gifConfig = VideoFFmpegVideoEditorConfig(
      _controller,
      format: VideoExportFormat.gif,
    );
    // Returns the generated command and the output path
    final FFmpegVideoEditorExecute gifExecute =
        await gifConfig.getExecuteConfig();

    // ...
  }

  Future<void> saveEditedVideo() async {
    Directory cacheDir = await getTemporaryDirectory();
    String videoPath = '${cacheDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    String command =
        '-i $toSavePath -ss ${_controller.startTrim.inSeconds} -t ${_controller.endTrim.inSeconds - _controller.startTrim.inSeconds} -vf scale=720:1280 -c copy $videoPath';
    await FFmpegKit.execute(command).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Video Trimmed and Cached")));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const SelectImageScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Some Error Occurred")));
        List<Log> errors = await session.getAllLogs();
        for (int j = 0; j < errors.length; j++) {
          print(errors[j].getMessage());
        }
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const SelectImageScreen()));
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return audioLoading ? const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.red,
            ),
            Text('Inserting Audio',style: TextStyle(color: Colors.red),)
          ],
        ),
      ),
    ) : PopScope(
      onPopInvoked: (invoke) => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _topNavBar(),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CropGridViewer.preview(
                                      controller: _controller),
                                  AnimatedBuilder(
                                    animation: _controller.video,
                                    builder: (_, __) => AnimatedOpacity(
                                      opacity: _controller.isPlaying ? 0 : 1,
                                      duration: kThemeAnimationDuration,
                                      child: GestureDetector(
                                        onTap: _controller.video.play,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 170,
                              margin: const EdgeInsets.only(top: 10),
                              child: Column(
                                children: [
                                  const Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Trim ',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Icon(Icons.cut)
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: _trimSlider(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Video Effects',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            filterLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : videoEffectsWidget(),
                            const Text('Overlay Text'),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: TextFormField(
                                controller: imgVidController,
                                decoration: InputDecoration(
                                    hintText: 'Enter text to apply on Vid',
                                    hintStyle: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w100),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        applyTextOnVideo();
                                      },
                                      icon: const Icon(
                                        Icons.add_box,
                                        color: Colors.red,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Row videoEffectsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () async {
            setState(() {
              filterLoading = true;
            });
            toSavePath = await applyEffect(toSavePath, 1);
            if (toSavePath != '') {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Retro Effect')));
              setState(() {
                filterLoading = false;
                _controller = VideoEditorController.file(File(toSavePath),
                    minDuration: const Duration(seconds: 1),
                    maxDuration: const Duration(seconds: 20));
                _controller
                    .initialize(aspectRatio: aspectratio)
                    .then((_) => setState(() {}));
              });
            }
          },
          child: Container(
              height: 40,
              width: 50,
              color: Colors.red.shade500,
              child: const Center(
                  child: Text('Retro', style: TextStyle(color: Colors.white)))),
        ),
        InkWell(
          onTap: () async {
            setState(() {
              filterLoading = true;
            });
            toSavePath = await applyEffect(toSavePath, 2);
            if (toSavePath != '') {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Curves Effect')));
              setState(() {
                filterLoading = false;
                _controller = VideoEditorController.file(File(toSavePath),
                    minDuration: const Duration(seconds: 1),
                    maxDuration: const Duration(seconds: 20));
                _controller
                    .initialize(aspectRatio: aspectratio)
                    .then((_) => setState(() {}));
              });
            }
          },
          child: Container(
              height: 40,
              width: 60,
              color: Colors.pink.shade500,
              child: const Center(
                  child:
                      Text('Curves', style: TextStyle(color: Colors.white)))),
        ),
        InkWell(
          onTap: () async {
            setState(() {
              filterLoading = true;
            });
            toSavePath = await applyEffect(toSavePath, 3);
            if (toSavePath != '') {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Noise Effect')));
              setState(() {
                filterLoading = false;
                _controller = VideoEditorController.file(File(toSavePath),
                    minDuration: const Duration(seconds: 1),
                    maxDuration: const Duration(seconds: 20));
                _controller
                    .initialize(aspectRatio: aspectratio)
                    .then((_) => setState(() {}));
              });
            }
          },
          child: Container(
              height: 40,
              width: 50,
              color: Colors.purple.shade500,
              child: const Center(
                  child: Text('Noise', style: TextStyle(color: Colors.white)))),
        ),
      ],
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=> SelectImageScreen())),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(
              endIndent: 22,
              indent: 22,
              color: Colors.white,
            ),
            Expanded(
                child: IconButton(
                    onPressed: pickAudioFile,
                    icon: const Icon(
                      Icons.audiotrack,
                      color: Colors.white,
                    ))),
            const VerticalDivider(
              endIndent: 22,
              indent: 22,
              color: Colors.white,
            ),
            Expanded(
                child: TextButton(
              child: const Text("Save"),
              onPressed: saveEditedVideo,
            )
                // PopupMenuButton(
                //   // color: Colors.white,
                //   tooltip: 'Open export menu',
                //   icon: const Icon(Icons.save,color: Colors.white,),
                //   itemBuilder: (context) => [
                //     PopupMenuItem(
                //       onTap: (){},
                //       // _exportCover,
                //       child: const Text('Export cover',style: TextStyle(color: Colors.black87),),
                //     ),
                //     PopupMenuItem(
                //       // onTap: (){},
                //       onTap: _exportVideo,
                //       child: const Text('Export video',style: TextStyle(color: Colors.black87),),
                //     ),
                //   ],
                // ),
                ),
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final int duration = _controller.videoDuration.inSeconds;
          final double pos = _controller.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              Text(
                formatter(Duration(seconds: pos.toInt())),
                style: const TextStyle(color: Colors.white),
              ),
              const Expanded(child: SizedBox()),
              AnimatedOpacity(
                opacity: _controller.isTrimming ? 1 : 0,
                duration: kThemeAnimationDuration,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    formatter(_controller.startTrim),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatter(_controller.endTrim),
                    style: const TextStyle(color: Colors.white),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: _controller,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }
}
