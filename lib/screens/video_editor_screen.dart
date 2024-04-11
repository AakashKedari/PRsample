import 'dart:developer';
import 'dart:io';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
// import 'package:ffmpeg_kit_flutter/log.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
// import 'package:ffmpeg_kit_flutter/session.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_full/session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/utils/constants.dart';
import 'package:prsample/customWidgets/loading_indicators.dart';
import 'package:prsample/utils/filters.dart';
import 'package:prsample/screens/audio_trimmer_screen.dart';
import 'package:prsample/screens/text_drag_screen.dart';
import 'package:prsample/screens/select_files_screen.dart';
import 'package:video_editor/video_editor.dart';

import '../audio_trimmer/trim_viewer.dart';
import '../audio_trimmer/trimmer.dart';

class VideoEditor extends StatefulWidget {
  const VideoEditor(
      {super.key,
      required this.file,
      required this.collageFlag,
      this.videoDuration = 30});

  final File file;
  final bool collageFlag;
  final int videoDuration;

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final double height = 60;
  TextEditingController imgVidController = TextEditingController();
  String globalAudiofilePath = '';
  late VideoEditorController _controller = VideoEditorController.file(
    widget.file,
    minDuration: const Duration(seconds: 1),
    maxDuration: Duration(seconds: widget.videoDuration),
  );

  /*Defining Two Paths because we cannot undo the filtering applied on Video So we make two paths for filtered & non-filtered videos*/
  late String toSavePath;
  String filteredToSavePath = '';
  String singleAudAdjustedPath = '';
  String doubleAudAdjustedPath = '';
  bool filterLoading = false;
  int filterFlag = -1;
  bool audioLoading = false;
  bool audioPicked = false;
  double vidHeight = 0.0;
  double vidWidth = 0.0;
  late double aspectratio;
  bool scaleAdjust = false;
  bool saveFlag = false;
  String selectedColor = 'White';
  String fontSize = '21';
  String font = 'openSans';

  @override
  void initState() {
    toSavePath = widget.file.path;
    super.initState();
    FFprobeKit.getMediaInformationAsync(toSavePath, (session) async {
      final information = (session).getMediaInformation()!;
      int h = information.getAllProperties()!['streams'][0]['height'];
      vidHeight = h.toDouble();
      int w = information.getAllProperties()!['streams'][0]['width'];
      vidWidth = w.toDouble();

      if (vidHeight != 1280 && vidWidth != 720 && !widget.collageFlag) {
        convertVidtoDesiredScale(toSavePath);
      }
      double bigValue = vidWidth / vidHeight; // Example double value

      aspectratio = double.parse(bigValue.toStringAsFixed(2));
      // if(vidWidth == 720 && vidHeight == 1280 && !widget.collageFlag){
      //   aspectratio =
      // }
    }).then((value) {
      Future.delayed(const Duration(seconds: 1)).then((value) {
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
    _controller.dispose();
    imgVidController.dispose();
    super.dispose();
  }

  void pickCollageAudioFile() async {
    Directory directory = await getTemporaryDirectory();
    setState(() {
      audioLoading = true;
    });
    try {
      FilePickerResult? pickedFiles = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.audio);

      if (pickedFiles != null && mounted) {
        String newFilePath = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AudioTrimmerView(
                      file: File(pickedFiles.files.first.path!),
                      time: widget.videoDuration,
                    )));

        String outputPath = '${directory.path}/audtemporary.mp4';

        /// Here we introduce the Dialog Box for Audio Adjustments
        // showAudioOverlayDialog(context,newFilePath);

        String choosingInputFile =
            filterFlag == -1 ? toSavePath : filteredToSavePath;

        String commandtoExecute =
            " -i $choosingInputFile -i $newFilePath -filter_complex '[1:a]volume=0.5[a]' -map 0:v -map '[a]' -c:v copy -b:v 10M -c:a aac -y $outputPath";

        // '-i $choosingInputFile -i $newFilePath -map 0:v -map 1:a -c:v copy -c:a aac -y $outputPath';

        if (filterFlag == -1) {
          toSavePath = outputPath;
        } else {
          filteredToSavePath = outputPath;
        }

        await FFmpegKit.execute(commandtoExecute).then((session) async {
          ReturnCode? variable = await session.getReturnCode();

          if (variable?.isValueSuccess() == true) {
            ///assigning audioFilePath the picked audio path to adjust volumes
            globalAudiofilePath = newFilePath;
            print('Video conversion successful');
            setState(() {
              audioLoading = false;
              _controller = VideoEditorController.file(File(outputPath),
                  minDuration: const Duration(seconds: 1),
                  maxDuration: Duration(seconds: widget.videoDuration + 2));
              _controller
                  .initialize(aspectRatio: aspectratio)
                  .then((_) => setState(() {
                        audioPicked = true;
                      }));
            });
          } else {
            setState(() {
              audioLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Operation Failed!!!')));
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

  Future<void> adjustVolume(double level) async {
    setState(() {
      audioLoading = true;
    });
    Directory directory = await getTemporaryDirectory();
    String big = level.toStringAsFixed(2);
    double? finallvl = double.tryParse(big);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(finallvl.toString())));

    String videoPath = filterFlag == -1 ? toSavePath : filteredToSavePath;
    singleAudAdjustedPath = '${directory.path}/clgaudtemporary.mp4';

    String commandtoExecute =
        " -i $videoPath -i $globalAudiofilePath -filter_complex '[1:a]volume=$finallvl[a]' -map 0:v -map '[a]' -c:v copy -c:a aac -y $singleAudAdjustedPath";

    // log("Adjust Volume Command : ${commandtoExecute}");
    FFmpegKit.execute(commandtoExecute).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        print('Video conversion successful');

        _controller = VideoEditorController.file(
            File('${directory.path}/clgaudtemporary.mp4'),
            minDuration: const Duration(seconds: 1),
            maxDuration: Duration(seconds: widget.videoDuration + 2));
        _controller
            .initialize(aspectRatio: aspectratio)
            .then((value) => setState(() {
                  audioLoading = false;
                }));
      } else {
        setState(() {
          audioLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error Adjusting Volume')));
        final List<Log> info = await session.getAllLogs();
        for (int i = 0; i < info.length; i++) {
          print(info[i].getMessage());
        }
      }
    });
  }

  void pickAudioForRealVideo() async {
    Directory directory = await getTemporaryDirectory();
    File? audioFile;
    setState(() {
      audioLoading = true;
    });
      FilePickerResult? pickedFile = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.audio);
      if(pickedFile != null){
        String audioPath = await Navigator.push(context, MaterialPageRoute(builder: (_)=> AudioTrimmerView(time: widget.videoDuration, file: File(pickedFile.files.first.path!))));
        final String videoPath =
        filterFlag == -1 ? toSavePath : filteredToSavePath;

        String outputPath =
            '${directory.path}/dualaudtemporary.mp4'; // Path to save the resulting video file

        final arguments = [
          '-y',
          '-i',
          videoPath,
          '-i',
          audioPath,
          '-filter_complex',
          '[0:a]volume=1.0[a1];[1:a]volume=1.0[a2];[a1][a2]amix=inputs=2:duration=first[aout]',
          '-map',
          '0:v',
          '-map',
          '[aout]',
          '-c:v',
          'copy',
          '-c:a',
          'aac',
          '-strict',
          'experimental',
          outputPath
        ];

        Session session = await FFmpegKit.executeWithArguments(arguments);
        ReturnCode? variable = await session.getReturnCode();

        if (variable!.isValueSuccess()) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Audio Success")));
          // globalAudiofilePath = audioFile!.path;
          globalAudiofilePath = audioPath;
          log('Custom audio added successfully');
          if (filterFlag == -1) {
            toSavePath = outputPath;
          } else {
            filteredToSavePath = outputPath;
          }
          globalAudiofilePath = audioPath;

          audioLoading = false;
          setState(() {
            _controller = VideoEditorController.file(File(outputPath),
                minDuration: const Duration(seconds: 1),
                maxDuration: Duration(seconds: widget.videoDuration + 2));
            _controller
                .initialize(aspectRatio: aspectratio)
                .then((_) => setState(() {
              audioPicked = true;
            }));
          });

        } else {
          setState(() {
            audioLoading = false;
          });
          print('Dual Audio Failed');
          final List<Log> info = await session.getAllLogs();
          for (int i = 0; i < info.length; i++) {
            print(info[i].getMessage());
          }

      }

      }
      // // Get the first selected file
      // audioFile = File(pickedFile!.files.first.path!);
      //
      // // Define a new file path in the cache directory
      // final String newFilePath =
      //     '${directory.path}/copied_audio.mp3'; // You can change the file extension as per your audio file type
      //
      // // Copy the file to the cache directory
      // await audioFile.copy(newFilePath);



  }

  Future<void> adjustVolumefortwoAudios(
      double primaryAudLvl, double secondaryAudLvl) async {
    String big = primaryAudLvl.toStringAsFixed(2);
    double? primary = double.tryParse(big);
    String big2 = secondaryAudLvl.toStringAsFixed(2);
    double? secondary = double.tryParse(big2);
    Directory directory = await getTemporaryDirectory();
    setState(() {
      audioLoading = true;
    });
    try {
      final String videoPath =
          filterFlag == -1 ? toSavePath : filteredToSavePath;
      final String audioPath = globalAudiofilePath;
      // String outputPath =
      //     '${directory.path}/twoaudtemporary.mp4'; // Path to save the resulting video file
      doubleAudAdjustedPath = '${directory.path}/twoaudtemporary.mp4';
      final arguments = [
        '-y',
        '-i',
        videoPath,
        '-i',
        audioPath,
        '-filter_complex',
        '[0:a]volume=${primary}[a1];[1:a]volume=${secondary}[a2];[a1][a2]amix=inputs=2:duration=first[aout]',
        '-map',
        '0:v',
        '-map',
        '[aout]',
        '-c:v',
        'copy',
        doubleAudAdjustedPath
      ];

      for (int i = 0; i < arguments.length; i++) {
        print(arguments[i]);
      }

      Session session = await FFmpegKit.executeWithArguments(arguments);
      ReturnCode? variable = await session.getReturnCode();

      if (variable!.isValueSuccess()) {
        FFmpegKit.cancel(session.getSessionId());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Volume Conversion Success"),
          duration: Duration(seconds: 1),
        ));

        /// Sort this out later for Video Saving Purpose
        // if (filterFlag == -1) {
        //   toSavePath = outputPath;
        // } else {
        //   filteredToSavePath = outputPath;
        // }
        globalAudiofilePath = audioPath;
        _controller.dispose();

        audioLoading = false;
        _controller = VideoEditorController.file(
            File('${directory.path}/twoaudtemporary.mp4'),
            minDuration: const Duration(seconds: 1),
            maxDuration: Duration(seconds: widget.videoDuration + 2));
        _controller
            .initialize(aspectRatio: aspectratio)
            .then((_) => setState(() {
                  audioPicked = true;
                }));
      } else {
        setState(() {
          audioLoading = false;
        });
        // log('Dual Audio Failed');
        final List<Log> info = await session.getAllLogs();
        for (int i = 0; i < info.length; i++) {
          print(info[i].getMessage());
        }
        FFmpegKit.cancel(session.getSessionId());
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


  Future<void> removeFilter(
      String receivedFilterVidPath, int filterNumber) async {
    setState(() {
      _controller = VideoEditorController.file(File(receivedFilterVidPath),
          minDuration: const Duration(seconds: 1),
          maxDuration: Duration(seconds: widget.videoDuration + 2));
      _controller.initialize(aspectRatio: aspectratio).then((_) => setState(() {
            filterFlag = -1;
          }));
    });
  }

  Future<void> saveEditedVideo() async {
    setState(() {
      saveFlag = true;
    });
    Directory cacheDir = await getTemporaryDirectory();
    String videoPath =
        '${cacheDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    String command = '';
    if (filterFlag == -1) {
      command =
          '-i $toSavePath -ss ${_controller.startTrim.inSeconds} -t ${_controller.endTrim.inSeconds - _controller.startTrim.inSeconds} -vf scale=720:1280 -b:v 10M $videoPath';
    } else {
      command =
          '-i $filteredToSavePath -ss ${_controller.startTrim.inSeconds} -t ${_controller.endTrim.inSeconds - _controller.startTrim.inSeconds} -vf scale=720:1280 -b:v 10M $videoPath';
    }

    await FFmpegKit.execute(command).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video Trimmed and Cached")));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SelectImageScreen()));
      } else {
        setState(() {
          saveFlag = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error Saving Video")));
        List<Log> errors = await session.getAllLogs();
        for (int j = 0; j < errors.length; j++) {
          print(errors[j].getMessage());
        }
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SelectImageScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return audioLoading
        ? Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 80, child: ballClipRoateWidget()),
                  Text(
                    scaleAdjust ? 'Adjusting Scale' : 'Inserting Audio',
                    style: const TextStyle(color: Color(0xFFFF005C)),
                  )
                ],
              ),
            ),
          )
        : PopScope(
            onPopInvoked: (invoke) => false,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: _controller.initialized
                  ? SafeArea(
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _topNavBar(),
                              Expanded(
                                child: DefaultTabController(
                                  length: 2,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            if (audioPicked &&
                                                !widget.collageFlag)
                                              LeftVerticalSlider(),
                                            if (!widget.collageFlag)
                                              SizedBox(
                                                width: 250,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    CropGridViewer.preview(
                                                        controller:
                                                            _controller),
                                                    AnimatedBuilder(
                                                      animation:
                                                          _controller.video,
                                                      builder: (_, __) =>
                                                          AnimatedOpacity(
                                                        opacity: _controller
                                                                .isPlaying
                                                            ? 0
                                                            : 1,
                                                        duration:
                                                            kThemeAnimationDuration,
                                                        child: GestureDetector(
                                                          onTap: _controller
                                                              .video.play,
                                                          child: Container(
                                                            width: 40,
                                                            height: 40,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: const Icon(
                                                              Icons.play_arrow,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (widget.collageFlag)
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CropGridViewer.preview(
                                                      controller: _controller),
                                                  AnimatedBuilder(
                                                    animation:
                                                        _controller.video,
                                                    builder: (_, __) =>
                                                        AnimatedOpacity(
                                                      opacity:
                                                          _controller.isPlaying
                                                              ? 0
                                                              : 1,
                                                      duration:
                                                          kThemeAnimationDuration,
                                                      child: GestureDetector(
                                                        onTap: _controller
                                                            .video.play,
                                                        child: Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: Colors.white,
                                                            shape:
                                                                BoxShape.circle,
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
                                            if (audioPicked) VerticalSlider()
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
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFFFF005C)),
                                                  ),
                                                  Icon(
                                                    Icons.cut,
                                                    color: Color(0xFFFF005C),
                                                  )
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
                                        style: TextStyle(
                                          color: Color(0xFFFF005C),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      filterLoading
                                          ? const SizedBox(
                                              height: 30,
                                              child: LoadingIndicator(
                                                colors: [
                                                  Colors.orange,
                                                  Colors.red,
                                                  Colors.yellow
                                                ],
                                                strokeWidth: 4,
                                                indicatorType:
                                                    Indicator.ballPulseSync,
                                              ),
                                            )
                                          : videoEffectsWidget(),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: LoadingIndicator(
                      indicatorType: Indicator.ballPulse,
                    )),
            ),
          );
  }

  Widget videoEffectsWidget() {
    return filterFlag != -1
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              centerFilterWidget(),
            ],
          )
        : SizedBox(
            width: double.infinity,
            height: 30,
            child: ListView.builder(
                itemCount: filterNames.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      setState(() {
                        filterLoading = true;
                        filterFlag = index;
                      });
                      filteredToSavePath =
                          await applyFilters(toSavePath, index + 1);
                      if (filteredToSavePath != '') {
                        setState(() {
                          filterLoading = false;
                          _controller = VideoEditorController.file(
                              File(filteredToSavePath),
                              minDuration: const Duration(seconds: 1),
                              maxDuration:
                                  Duration(seconds: widget.videoDuration + 2));
                          _controller
                              .initialize(aspectRatio: aspectratio)
                              .then((_) => setState(() {}));
                        });
                      } else {
                        setState(() {
                          filterLoading = false;
                        });
                        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Occurred")));
                      }
                    },
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 30,
                        ),
                        Container(
                            height: 40,
                            width: 60,
                            color: filterColors[index],
                            child: Center(
                                child: Text(filterNames[index],
                                    style:
                                        const TextStyle(color: Colors.white)))),
                        const SizedBox(
                          width: 30,
                        )
                      ],
                    ),
                  );
                }),
          );
  }

  Stack centerFilterWidget() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              height: 30,
              width: 60,
              color: filterColors[filterFlag],
              child: Center(
                  child: Text(filterNames[filterFlag],
                      style: const TextStyle(color: Colors.white)))),
        ),
        Positioned(
            right: -15,
            top: -15,
            child: IconButton(
              iconSize: 20,
              onPressed: () {
                removeFilter(toSavePath, filterFlag);
              },
              icon: const Icon(
                Icons.cancel,
                color: Colors.white,
              ),
            ))
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
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const SelectImageScreen())),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color.fromRGBO(255, 0, 92, 1),
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
                child:
                    // volDropDown()
                    IconButton(
                        onPressed: () {
                          widget.collageFlag
                              ? pickCollageAudioFile()
                              : pickAudioForRealVideo();
                        },
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
                child: IconButton(
                    onPressed: () {
                      showTextOverlayDialog(context);
                    },
                    icon: const Icon(
                      Icons.text_fields,
                      color: Colors.white,
                    ))),
            const VerticalDivider(
              endIndent: 22,
              indent: 22,
              color: Colors.white,
            ),
            Expanded(
                child: TextButton(
              onPressed: saveEditedVideo,
              child: saveFlag ? ballClipRoateWidget() : const Text("Save"),
            )),
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

  double _leftSliderVolLvl = 0.5;
  double _rightSliderVolLvL = 0.5;

  Widget VerticalSlider() {
    return Column(
      children: [
        if (widget.collageFlag == true)
          IconButton(
            icon: const Icon(
              Icons.cancel_rounded,
              color: Colors.red,
            ),
            onPressed: () {
              setState(() {
                if (filterFlag == -1) {
                  toSavePath = singleAudAdjustedPath;
                } else {
                  filteredToSavePath = singleAudAdjustedPath;
                }
                audioPicked = false;
                log("Cross Pressed");
              });
            },
          ),
        RotatedBox(
          quarterTurns: 3,
          child: Slider(
            // allowedInteraction: SliderInteraction.values.single,
            label: 'Volume Level',
            thumbColor: Colors.red,
            value: _rightSliderVolLvL,
            min: 0.0,
            max: 2.0,
            onChangeEnd: (newValue) {
              _rightSliderVolLvL = newValue;
              print(_rightSliderVolLvL.toString());
              if (widget.collageFlag) {
                adjustVolume(_rightSliderVolLvL);
              } else {
                adjustVolumefortwoAudios(_rightSliderVolLvL, _leftSliderVolLvl);
              }
            },
            activeColor: Colors.white,
            inactiveColor: Colors.grey[300],
            onChanged: (double value) {
              setState(() {
                _rightSliderVolLvL = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget LeftVerticalSlider() {
    return Column(
      children: [
        IconButton(
          icon: const Icon(
            Icons.cancel_rounded,
            color: Colors.red,
          ),
          onPressed: () {
            setState(() {
              if (filterFlag == -1) {
                toSavePath = doubleAudAdjustedPath;
              } else {
                filteredToSavePath = doubleAudAdjustedPath;
              }
              audioPicked = false;
              log("Cross Pressed");
            });
          },
        ),
        RotatedBox(
          quarterTurns: 3,
          child: Slider(
            // allowedInteraction: SliderInteraction.values.single,
            label: 'Volume Level',
            thumbColor: Colors.red,
            value: _leftSliderVolLvl,
            min: 0.0,
            max: 2.0,
            onChangeEnd: (newValue) {
              _leftSliderVolLvl = newValue;
              adjustVolumefortwoAudios(_rightSliderVolLvL, _leftSliderVolLvl);
            },
            activeColor: Colors.white,
            inactiveColor: Colors.grey[300],
            onChanged: (double value) {
              setState(() {
                _leftSliderVolLvl = value;
              });
            },
          ),
        ),
      ],
    );
  }

  void convertVidtoDesiredScale(String incomingVidPath) async {
    Directory directory = await getTemporaryDirectory();
    setState(() {
      audioLoading = true;
      scaleAdjust = true;
    });
    final arguments = [
      '-y',
      '-i',
      incomingVidPath,
      '-vf',
      'scale=720:1280',

      '-c:a',
      'aac',
      '${directory.path}/scale-temporary.mp4'
    ];

    await FFmpegKit.executeWithArguments(arguments).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        FFprobeKit.getMediaInformationAsync(
          '${directory.path}/scale-temporary.mp4',
          (session) async {
            final information = (session).getMediaInformation()!;
            int h = information.getAllProperties()!['streams'][0]['height'];
            vidHeight = h.toDouble();
            int w = information.getAllProperties()!['streams'][0]['width'];
            vidWidth = w.toDouble();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("height : ${vidHeight} & Width : $vidWidth")));
          },
        );
        vidWidth = 720;
        vidHeight = 1280;
        double bigValue = vidWidth / vidHeight; // Example double value

        aspectratio = double.parse(bigValue.toStringAsFixed(2));
        setState(() {
          toSavePath = '${directory.path}/scale-temporary.mp4';
          _controller = VideoEditorController.file(
              File('${directory.path}/scale-temporary.mp4'),
              minDuration: const Duration(seconds: 1),
              maxDuration: const Duration(seconds: 20));
          _controller.initialize(aspectRatio: 9 / 16).then((_) => setState(() {
                audioLoading = false;
              }));
        });
      } else {

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Some Error Occurred")));
        Navigator.pop(context);
        List<Log> errors = await session.getAllLogs();
        for (int j = 0; j < errors.length; j++) {
          print(errors[j].getMessage());
        }
      }
    });
  }

  void showTextOverlayDialog(
    BuildContext context,
  ) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          // Get the current theme data
          final theme = Theme.of(context);

          // Determine if the current theme is dark or light
          final isDarkMode = theme.brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: Colors.red,
            title: const Text('Overlay Text'),
            content: SizedBox(
              width:
                  MediaQuery.of(context).size.width, // Adjust width as needed
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                      controller: imgVidController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Text to apply',
                        hintStyle: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w100),
                      )),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: DropdownButton(
                        value: font,
                        hint: const Text('Font'),
                        items: fonts.map((String value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            font = value!;
                          });
                          Navigator.pop(context);
                          showTextOverlayDialog(context);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: DropdownButton(
                        value: fontSize,
                        hint: const Text('FontSize'),
                        items: fontSizes.map((String value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (selection) {
                          setState(() {
                            fontSize = selection!;
                            log('fontSize : ${fontSize}');
                            Navigator.pop(context);
                            showTextOverlayDialog(context);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          height: 40,
                          width: 40,
                          color: colorMap[selectedColor]),
                      SizedBox(
                        height: 40,
                        child: Center(
                          child: DropdownButton(
                            value: selectedColor,
                            hint: const Text('Color'),
                            items: textColors.map((String value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (selection) {
                              setState(() {
                                selectedColor = selection!;
                                log('fontSize : ${fontSize}');
                                Navigator.pop(context);
                                showTextOverlayDialog(context);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Center(
                      child: ElevatedButton(
                          onPressed: () async {
                            String textdonepath = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => VideoOverlayWidget(
                                          editingVidPath: filterFlag == -1
                                              ? toSavePath
                                              : filteredToSavePath,
                                          text: imgVidController.text,
                                          textStyle: TextStyle(
                                              fontFamily: font,
                                              fontSize: double.parse(fontSize),
                                              color: colorMap[selectedColor]),
                                        )));
                            if (filterFlag == -1) {
                              toSavePath = textdonepath;
                            } else {
                              filteredToSavePath = textdonepath;
                            }
                            setState(() {
                              Navigator.pop(context);

                              _controller = VideoEditorController.file(
                                  File(textdonepath),
                                  minDuration: const Duration(seconds: 1),
                                  maxDuration: Duration(
                                      seconds: widget.videoDuration + 2));
                              _controller
                                  .initialize(aspectRatio: aspectratio)
                                  .then((value) => setState(() {}));
                            });
                          },
                          child: (const Text('Apply'))))
                ],
              ),
            ),
          );
        });
  }

  void showAudioOverlayDialog(BuildContext context, String audioFile) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          File audio = File(audioFile);
          Trimmer _trimmer = Trimmer();
          _trimmer.loadAudio(audioFile: audio);
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Audio Adjustments'),
            content: Column(
              children: [
                TrimViewer(trimmer: _trimmer),
                ElevatedButton(onPressed: () {}, child: const Text("Trim"))
              ],
            ),
          );
        });
  }
}
