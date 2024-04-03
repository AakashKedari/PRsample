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
import 'package:prsample/constants.dart';
import 'package:prsample/customWidgets/volume_slider.dart';
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

  final double height = 60;
  TextEditingController imgVidController = TextEditingController();
  String audioFilePath = '';
  late VideoEditorController _controller = VideoEditorController.file(
    widget.file,
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 20),
  );
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
      double bigValue = vidWidth / vidHeight; // Example double value
      aspectratio = double.parse(bigValue.toStringAsFixed(2));

      // log("height : ${information.getAllProperties()!['streams'][0]['width'].toString()}");
      // log("width : ${information.getAllProperties()!['streams'][0]['height'].toString()}");
      // log('aspectratio : $aspectratio');
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

    _controller.dispose();
    // ExportService.dispose();
    super.dispose();
  }

  Future<void> pickAudioFile(double volume) async {
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
            " -i $choosingInputFile -i $newFilePath -filter_complex '[1:a]volume=${volume}[a]' -map 0:v -map '[a]' -c:v copy -c:a aac -y $outputPath";

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
            audioFilePath = newFilePath;
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

  Future<void> applyTextOnVideo() async {
    Directory directory = await getTemporaryDirectory();
    String tempTextOverlayPath = '${directory.path}/texttemporary.mp4';
    String command = ' -i $toSavePath -vf "drawtext=text='
        "${imgVidController.value.text.toString()}"
        ':fontcolor=purple:fontsize=50:x=200:y=200" -c:a copy $tempTextOverlayPath';
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
        });
      } else {
        setState(() {});
        final List<Log> info = await session.getAllLogs();
        for (int i = 0; i < info.length; i++) {
          print(info[i].getMessage());
        }
      }
    });
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
    // String videoPath = '/storage/emulated/0/Download/kb.mp4';
    String videoPath =
        '${cacheDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    String command = '';
    if (filterFlag == -1) {
      command =
          '-i $toSavePath -ss ${_controller.startTrim.inSeconds} -t ${_controller.endTrim.inSeconds - _controller.startTrim.inSeconds} -vf scale=720:1280 $videoPath';
    } else {
      command =
          '-i $filteredToSavePath -ss ${_controller.startTrim.inSeconds} -t ${_controller.endTrim.inSeconds - _controller.startTrim.inSeconds} -vf scale=720:1280 $videoPath';
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

  Future<void> removeFilter(String receivedFilterVidPath, int filterNumber) async {
    setState(() {
      _controller = VideoEditorController.file(File(receivedFilterVidPath),
          minDuration: const Duration(seconds: 1),
          maxDuration: const Duration(seconds: 20));
      _controller.initialize(aspectRatio: aspectratio).then((_) => setState(() {
            filterFlag = -1;
          }));
    });
  }

  Future<void> adjustVolume(double level) async {
    setState(() {
      audioLoading = true;
    });
    Directory directory = await getTemporaryDirectory();
    String temp = _value.toStringAsFixed(1);
    double volumeLvL = double.parse(temp);
    log(volumeLvL.toString());
    String choosingInputFile =
    filterFlag == -1 ? toSavePath : filteredToSavePath;
    String commandtoExecute =
        " -i $choosingInputFile -i $audioFilePath -filter_complex '[1:a]volume=$level[a]' -map 0:v -map '[a]' -c:v copy -c:a aac -y ${'${directory.path}/audadjusttemporary.mp4'}";
    await FFmpegKit.execute(commandtoExecute).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        ///assigning audioFilePath the picked audio path to adjust volumes

        print('Video conversion successful');
        audioPicked = false;
        // audioLoading = false;
        _controller = VideoEditorController.file(File(audioFilePath),
            minDuration: const Duration(seconds: 1),
            maxDuration: const Duration(seconds: 20));
        _controller
            .initialize(aspectRatio: aspectratio)
            .then((_) => setState(() {
              audioLoading=false;
          // audioPicked = true;
        }));
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
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                CropGridViewer.preview(
                                                    controller: _controller),
                                                AnimatedBuilder(
                                                  animation: _controller.video,
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
                                            // if(audioPicked)
                                            //   volDropDown()

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
                              )
                            ],
                          ),
                          if (textTyping)
                            AlertDialog(
                              content: SizedBox(
                                height: 150,
                                width: 300,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Overlay Text'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: TextFormField(
                                        controller: imgVidController,
                                        decoration: InputDecoration(
                                            hintText: 'Text to apply',
                                            hintStyle: const TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w100),
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                applyTextOnVideo().then(
                                                    (value) => setState(() {
                                                          textTyping = false;
                                                        }));
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
                child: volDropDown()
                // IconButton(
                //     onPressed: (){
                //       volDropDown();
                //     }
                //     pickAudioFile,
                //
                //     icon: const Icon(
                //       Icons.audiotrack,
                //       color: Colors.white,
                //     ))
            ),
            const VerticalDivider(
              endIndent: 22,
              indent: 22,
              color: Colors.white,
            ),
            Expanded(
                child: IconButton(
                    onPressed: () {
                      setState(() {
                        textTyping = true;
                      });
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
            )

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

  double _value = 0.5;

  Widget VerticalSlider() {
    return RotatedBox(
      quarterTurns: 3,
      child: Slider(
        value: _value,
        min: 0.0,
        max: 1.0,
        onChangeEnd: (newValue) {
          Future.delayed(Duration(seconds: 2)).then((value) {

              log('#################################Slider Changeddddddddddd');
              _value = newValue;
              log(_value.toString());
              // adjustVolume();
              setState(() {

              });

          });

        },
        activeColor: Colors.white,
        inactiveColor: Colors.grey[300],
        onChanged: (double value) {

        },
      ),
    );
  }
  Widget volDropDown() {

    double _selectedValue = 0.0;

    List<double> dropdownValues = List.generate(11, (index) => index / 5);

    return DropdownButton<double>(
      icon:const Icon(Icons.audiotrack,color: Colors.white,),

      value: _selectedValue,
      onChanged: (newValue) {
          _selectedValue = newValue!;
        pickAudioFile(_selectedValue);

      },
      items: dropdownValues.map<DropdownMenuItem<double>>((double value) {
        return DropdownMenuItem<double>(
          value: value,
          child: Text('$value'),
        );
      }).toList(),
    );
  }
}
