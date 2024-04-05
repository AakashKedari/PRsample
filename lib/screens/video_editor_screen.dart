import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_full/session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/constants.dart';
import 'package:prsample/filters.dart';
import 'package:prsample/screens/drag_screen.dart';
import 'package:prsample/screens/selectfiles.dart';
import 'package:video_editor/video_editor.dart';

class VideoEditor extends StatefulWidget {
  const VideoEditor({super.key, required this.file, required this.collageFlag,this.videoDuration=20});

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
    maxDuration:  Duration(seconds: widget.videoDuration),
  );

  /*Defining Two Paths because we cannot undo the filtering applied on Video So we make two paths for filtered & non-filtered videos*/
  late String toSavePath;
  String filteredToSavePath = '';

  bool filterLoading = false;
  int filterFlag = -1;
  bool audioLoading = false;
  bool audioPicked = false;
  double vidHeight = 0.0;
  double vidWidth = 0.0;
  late double aspectratio;
  bool textTyping = false;
  int fCount = 0;

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

      if (pickedFiles != null) {
        // Get the first selected file
        final file = File(pickedFiles.files.first.path!);

        // Define a new file path in the cache directory
        final String newFilePath =
            '${directory.path}/copied_audio.mp3'; // You can change the file extension as per your audio file type

        // Copy the file to the cache directory
        await file.copy(newFilePath);

        // Below command to replace a video's sound
        String outputPath = '${directory.path}/audtemporary.mp4';
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
                  maxDuration: const Duration(seconds: 20));
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
      fCount = fCount + 1;
    });
    Directory directory = await getTemporaryDirectory();
    String big = level.toStringAsFixed(2);
    double? finallvl = double.tryParse(big);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(finallvl.toString())));

    String videoPath = filterFlag == -1 ? toSavePath : filteredToSavePath;

    String commandtoExecute =
        " -i $videoPath -i $globalAudiofilePath -filter_complex '[1:a]volume=${finallvl}[a]' -map 0:v -map '[a]' -c:v copy -c:a aac -y ${'${directory.path}/clgaudtemporary.mp4'}";

    // log("Adjust Volume Command : ${commandtoExecute}");
    FFmpegKit.execute(commandtoExecute).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        print('Video conversion successful');
        // if(filterFlag == -1){
        //   toSavePath = '${directory.path}/audadjusttemporary.mp4';
        // }
        // else{
        //   filteredToSavePath = '${directory.path}/audadjusttemporary.mp4';
        // }

        _controller = VideoEditorController.file(
            File('${directory.path}/clgaudtemporary.mp4'),
            minDuration: const Duration(seconds: 1),
            maxDuration: const Duration(seconds: 20));
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
    try {
      FilePickerResult? pickedFile = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.audio);

      // Get the first selected file
      audioFile = File(pickedFile!.files.first.path!);

      // Define a new file path in the cache directory
      final String newFilePath =
          '${directory.path}/copied_audio.mp3'; // You can change the file extension as per your audio file type

      // Copy the file to the cache directory
      await audioFile.copy(newFilePath);

      final String videoPath =
          filterFlag == -1 ? toSavePath : filteredToSavePath;
      final String audioPath = newFilePath;
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
            .showSnackBar(SnackBar(content: Text("Audio Success")));
        globalAudiofilePath = audioFile!.path;
        print('Custom audio added successfully');
        if (filterFlag == -1) {
          toSavePath = outputPath;
        } else {
          filteredToSavePath = outputPath;
        }
        globalAudiofilePath = audioPath;

        audioLoading = false;
        _controller = VideoEditorController.file(File(outputPath),
            minDuration: const Duration(seconds: 1),
            maxDuration: const Duration(seconds: 20));
        _controller
            .initialize(aspectRatio: aspectratio)
            .then((_) => setState(() {
                  audioPicked = true;
                }));
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
          maxDuration: const Duration(seconds: 20));
      _controller.initialize(aspectRatio: aspectratio).then((_) => setState(() {
            filterFlag = -1;
          }));
    });
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
      fCount = fCount + 1;
    });
    try {
      final String videoPath =
          filterFlag == -1 ? toSavePath : filteredToSavePath;
      final String audioPath = globalAudiofilePath;
      String outputPath =
          '${directory.path}/twoaudtemporary.mp4'; // Path to save the resulting video file

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
        outputPath
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

        // globalAudiofilePath = audioFile!.path;
        // print('Dual Audio added successfully');

        /// Sort this out later for Video Saving Purpose
        // if (filterFlag == -1) {
        //   toSavePath = outputPath;
        // } else {
        //   filteredToSavePath = outputPath;
        // }
        globalAudiofilePath = audioPath;
        _controller.dispose();

        audioLoading = false;
        _controller = VideoEditorController.file(File(outputPath),
            minDuration: const Duration(seconds: 1),
            maxDuration: const Duration(seconds: 20));
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

  Future<void> saveEditedVideo() async {
    Directory cacheDir = await getTemporaryDirectory();
    String videoPath =
        '${cacheDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    // '/storage/emulated/0/Download/${DateTime.now().microsecond}.mp4';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Some Error Occurred")));
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
        ? const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.red,
                  ),
                  Text(
                    'Inserting Audio',
                    style: TextStyle(color: Colors.red),
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
                                                        color: Colors.white),
                                                  ),
                                                  Icon(
                                                    Icons.cut,
                                                    color: Colors.white,
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
                  : const Center(child: CircularProgressIndicator()),
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
                              maxDuration: const Duration(seconds: 20));
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
              height: 40,
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
              child: const Text("Save"),
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
    return RotatedBox(
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
    );
  }

  Widget LeftVerticalSlider() {
    return RotatedBox(
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

          // log(_leftSliderVolLvl.toString());

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
    );
  }

  void convertVidtoDesiredScale(String incomingVidPath) async {
    Directory directory = await getTemporaryDirectory();
    setState(() {
      audioLoading = true;
    });
    final arguments = [
      '-y',
      '-i', incomingVidPath,
      '-vf', 'scale=1280:720',
      '-preset', 'medium',
      '-crf', '23',
      '-c:a', 'aac',
      '${directory.path}/scale-temporary.mp4'

    ];
    await FFmpegKit.executeWithArguments(arguments).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        vidWidth = 720;
        vidHeight = 1280;
        double bigValue = vidWidth / vidHeight; // Example double value

        aspectratio = double.parse(bigValue.toStringAsFixed(2));
        setState(() {
          _controller = VideoEditorController.file(
              File('/storage/emulated/0/Download/scaled.mp4'),
              minDuration: const Duration(seconds: 1),
              maxDuration: const Duration(seconds: 20));
          _controller
              .initialize(aspectRatio: 16/9)
              .then((_) => setState(() {
            audioLoading = false;
          }));
        });

      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Some Error Occurred")));
        List<Log> errors = await session.getAllLogs();
        for (int j = 0; j < errors.length; j++) {
          print(errors[j].getMessage());
        }
      }
    });
  }

  void showTextOverlayDialog(BuildContext context,) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Get the current theme data
        final theme = Theme.of(context);

        // Determine if the current theme is dark or light
        final isDarkMode = theme.brightness == Brightness.dark;
        return
          AlertDialog(
            backgroundColor:  Colors.red ,
            title: const Text('Overlay Text'),
            content: SizedBox(
              height: 100,
              width: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15),
                child: TextFormField(
                  style: const TextStyle(color: Colors.black ),
                  controller: imgVidController,
                  decoration: InputDecoration(
                    filled: true,
                      fillColor: Colors.white,
                      hintText: 'Text to apply',
                      hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w100),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          String textdonepath = await Navigator.push(context, MaterialPageRoute(builder: (_)=> VideoOverlayWidget(editingVidPath: toSavePath,text: imgVidController.text,)));
                          if(filterFlag == -1){
                            toSavePath = textdonepath;
                          }
                          else{
                            filteredToSavePath = textdonepath;
                          }
                          setState(() {
                            textTyping = false;
                            _controller = VideoEditorController.file(
                                File(textdonepath),
                                minDuration: const Duration(seconds: 1),
                                maxDuration:  Duration(seconds: widget.videoDuration));
                            _controller
                                .initialize(aspectRatio: aspectratio)
                                .then((value) => setState(() {

                            }));
                          });
                          // applyTextOnVideo().then(
                          //     (value) => setState(() {
                          //           textTyping = false;
                          //         }));
                        },
                        icon: const Icon(
                          Icons.add_box,
                          color: Colors.red,
                        ),
                      ),
                     ),
                ),
              ),
            ),
          );
      },
    );
  }
}
