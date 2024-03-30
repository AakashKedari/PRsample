import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/filters.dart';
// import 'package:tapioca/tapioca.dart';
import 'package:video_editor/video_editor.dart';
import 'local_reel.dart';
// import 'package:video_editor/video_editor.dart';
import 'package:path_provider/path_provider.dart';

class SelectImageScreen extends StatefulWidget {
  const SelectImageScreen({super.key});

  @override
  State<SelectImageScreen> createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  final ImagePicker _picker = ImagePicker();

  void _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

    if (mounted && file != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => VideoEditor(file: File(file.path)),
        ),
      );
    }
  }

  int numberOfImages = 0;
  List<XFile> imagePath = [];

  void pickImages() async {
    isLoading = true;
    setState(() {});
    List<XFile> images = [];

    try {
      ImagePicker imagePicker = ImagePicker();
      List<XFile> imageesss = await imagePicker.pickMultiImage();
      print(imageesss.first.path);
      imagePath = imageesss;

      if (!imageesss.isEmpty) {

        totalImageSelected = imageesss.length;
        images = imageesss;
        print(images[0]);
        writingCustomImagePaths(imageesss.length,imageesss);
        for (int i = 0; i < images.length; i++) {
          // customImagePaths += images
          customImagePaths =
              customImagePaths + "-loop 1 -i " + images[i].path + " ";
        }
        // Before the function is called we have to get the number of images selected by user which is written above
        convertImagetoVideo();
      } else if (imageesss.isEmpty) {
        setState(() {
          print("Nothing Selected");
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Nothing Selected")));
          isLoading = false;
        });
      }
    } catch (e) {
      print("@@@@@@@@@@@@@@@@@@@@@Error picking images: $e");
    }

    // return images;
  }
  void convertImagetoVideo() async {
    Directory directory = await getTemporaryDirectory();
    String Base_path = directory.path;
    String output_path = Base_path + '/${DateTime.now().day.toString()}}.mp4';
    String outputmarg = '/storage/emulated/0/Download/ram.mp4';

    // Below command to rename and create a copy of a video
    // String  commandtoExecute = '-i ${video_path} -c:v mpeg4 ${output_path}';

    String command = "-hide_banner -y " +
        customImagePaths +
        "-filter_complex " +
        "\"[0:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,640/427),min(iw,640),-1)':h='if(gte(iw/ih,640/427),-1,min(ih,427))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream1out1][stream1out2];" +
        "[1:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,640/427),min(iw,640),-1)':h='if(gte(iw/ih,640/427),-1,min(ih,427))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream2out1][stream2out2];" +
        "[2:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,640/427),min(iw,640),-1)':h='if(gte(iw/ih,640/427),-1,min(ih,427))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream3out1][stream3out2];" +
        "[stream1out1]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=3,select=lte(n\\,90)[stream1overlaid];" +
        "[stream1out2]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30)[stream1ending];" +
        "[stream2out1]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=2,select=lte(n\\,60)[stream2overlaid];" +
        "[stream2out2]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30),split=2[stream2starting][stream2ending];" +
        "[stream3out1]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=2,select=lte(n\\,60)[stream3overlaid];" +
        "[stream3out2]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30)[stream3starting];" +
        "[stream2starting][stream1ending]blend=all_expr='if(gte(X,(W/2)*T/1)*lte(X,W-(W/2)*T/1),B,A)':shortest=1[stream2blended];" +
        "[stream3starting][stream2ending]blend=all_expr='if(gte(X,(W/2)*T/1)*lte(X,W-(W/2)*T/1),B,A)':shortest=1[stream3blended];" +
        "[stream1overlaid][stream2blended][stream2overlaid][stream3blended][stream3overlaid]concat=n=5:v=1:a=0,scale=w=640:h=424,format=" +
        "yuv420p" +
        "[video]\"" +
        " -map [video] -fps_mode cfr " +
        "" +
        "-c:v " +
        "mpeg4" +
        " -r 30 " +
        output_path;

    String command2 = "-hide_banner -y ";

// Iterate over each image stream
    for (int i = 0; i < numberOfImages; i++) {

      String imageStream = "-i " + imagePath[i].path + " ";
      String streamLabel = "[input" + i.toString() + ":v]";
      String processingFilters = "setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,640/427),min(iw,640),-1)':h='if(gte(iw/ih,640/427),-1,min(ih,427))'," +
          "scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream" + i.toString() + "out1][stream" + i.toString() + "out2];" +
          "[stream" + i.toString() + "out1]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,";

      // Determine trimming and selection duration based on stream index
      String trimDuration;
      if (i == 0) {
        trimDuration = "3";
      } else {
        trimDuration = "2";
      }

      // Add trimming and selection filters
      processingFilters += "trim=duration=" + trimDuration + ",select=lte(n\\," + ((i + 1) * 30).toString() + ")";

      if (i < numberOfImages - 1) {
        processingFilters += "[stream" + i.toString() + "overlaid];";
      } else {
        processingFilters += "[stream" + i.toString() + "ending];";
      }

      command2 += imageStream + streamLabel + processingFilters;
    }

// Combine all streams and set output options
    command2 += "concat=n=" + numberOfImages.toString() + ":v=1:a=0,scale=w=640:h=424,format=yuv420p[video]\" -map [video] -fps_mode cfr " +
        "-c:v mpeg4 -r 30 " +
        outputmarg;


    await FFmpegKit.execute(command2).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        print('Video conversion successful');

        // final path = output_path;
        Future.delayed(const Duration(seconds: 2)).then((value) {
          setState(() {
            isLoading = false;
          });
          try {
            print('now Play');
            // final tapiocaBalls = [
            //   TapiocaBall.filter(Filters.pink, 0.2),
            //   TapiocaBall.textOverlay("text", 100, 10, 100, Color(0xffffc0cb)),
            // ];
            print("will start");
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => VideoScreen(output_path)));

            // Navigator.pushReplacement(context, Video)
            // _navigateToVideoScreen(output_path);
            // final cup = Cup(Content(output_path), tapiocaBalls);
            // cup.suckUp(output_path).then((_) async {
            //   print("finished");
            //   setState(() {
            //
            //   });
            //   print('Probably edited video path $path');

            // Navigator.push(context,
            //   MaterialPageRoute(builder: (context) =>
            //       VideoScreen(path)),
            // );
            //
            // }).catchError((e) {
            //   print('Got error: $e');
            // });
          } catch (e) {
            print(e.toString());
          }
        });
      } else {
        print(
            'Video conversion failed with return code: ${session.getAllLogs()})}');
        print("Total number of images selected is : ${totalImageSelected}");
        List<Log> list = await session.getAllLogs();
        for (int i = 0; i < list.length; i++) {
          print(list[i].getMessage());
        }
      }
    }).catchError((error) {
      print('Error while executing FFmpeg command: $error');
    });
  }

  var loggerNoStack = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );
  void videoInfo() {
    FFprobeKit.getMediaInformationAsync(
        '/storage/emulated/0/Download/owner2.mp4', (session) async {
      final information = (await (session).getMediaInformation())!;
      loggerNoStack.t(information.getAllProperties());
      setState(() {});
    });
  }



  List<String> _selectedFiles = [];

  Future<void> pickFiles() async {
    try {
      FilePickerResult? pickedFiles = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (pickedFiles != null) {
        List<String> paths =
            pickedFiles.files.map((file) => file.path!).toList();

        // Check if exactly two files are selected
        if (paths.length != 2) {
          print('Please select exactly two files for merging.');
          return;
        }

        // Check if one file is audio and the other is video
        bool hasAudioFile = paths.any((path) =>
            path.toLowerCase().endsWith('.mp3') ||
            path.toLowerCase().endsWith('.aac'));
        bool hasVideoFile =
            paths.any((path) => path.toLowerCase().endsWith('.mp4'));
        if (!hasAudioFile || !hasVideoFile) {
          print(
              'Please select one audio file (.mp3 or .aac) and one video file (.mp4) for merging.');
          return;
        }

        setState(() {
          _selectedFiles = paths;
        });
        // Below command to replace a video's sound

        String commandtoExecute = '-i ${_selectedFiles[0]} -i ${_selectedFiles[1]} -c copy /storage/emulated/0/Download/${Random().nextInt(100)}.mp4';
        await FFmpegKit.execute(commandtoExecute).then((session) async {
          ReturnCode? variable = await session.getReturnCode();

          if (variable?.isValueSuccess() == true) {
            print('Video conversion successful');
            Navigator.push(context, MaterialPageRoute(builder: (_) => VideoScreen('/storage/emulated/0/Download/merger.mp4')));
          } else {
            print('No files selected.');
          }
        });
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paper Reels"),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: !isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Choose one of following Options"),
                  ElevatedButton(
                    onPressed: _pickVideo,
                    child: const Text("Pick Video From Gallery"),
                  ),
                  ElevatedButton(
                    onPressed: pickImages,
                    child: const Text("Image Collage"),
                  ),
                  ElevatedButton(
                    onPressed: pickFiles,
                    child: const Text("Add audio to video"),
                  ),
                ],
              ),
            )
          : Center(
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
    );
  }
}

//-------------------//
//VIDEO EDITOR SCREEN//
//-------------------//
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

  late final VideoEditorController _controller = VideoEditorController.file(
    widget.file,
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 20),
  );

  @override
  void initState() {
    super.initState();
    _controller
        .initialize(aspectRatio: 9 / 16)
        .then((_) => setState(() {
              Timer.periodic(Duration(seconds: 1), (time) {
                // duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
                print(
                    'starttrim##################${_controller.startTrim.inSeconds}');
                print(
                    'endtrim##################${_controller.endTrim.inSeconds}');
              });
            }))
        .catchError((error) {
      // handle minimum duration bigger than video duration error
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    // ExportService.dispose();
    super.dispose();
  }

  void _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;
    TextEditingController textEditingController = TextEditingController();

    // final config = VideoFFmpegVideoEditorConfig(
    //   _controller,
    //   // format: VideoExportFormat.gif,
    //   // commandBuilder: (config, videoPath, outputPath) {
    //   //   final List<String> filters = config.getExportFilters();
    //   //   filters.add('hflip'); // add horizontal flip
    //
    //   //   return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
    //   // },
    // );
    //
    // await ExportService.runFFmpegCommand(
    //   await config.getExecuteConfig(),
    //   onProgress: (stats) {
    //     _exportingProgress.value = config.getFFmpegProgress(stats.getTime());
    //   },
    //   onError: (e, s) => _showErrorSnackBar("Error on export video :("),
    //   onCompleted: (file) {
    //     _isExporting.value = false;
    //     if (!mounted) return;
    //
    //     // showDialog(
    //     //   context: context,
    //     //   builder: (_) => VideoResultPopup(video: file),
    //     // );
    //   },
    // );
  }

  // void _exportCover() async {
  //   final config = CoverFFmpegVideoEditorConfig(_controller);
  //   final execute = await config.getExecuteConfig();
  //   if (execute == null) {
  //     _showErrorSnackBar("Error on cover exportation initialization.");
  //     return;
  //   }
  //
  //   await ExportService.runFFmpegCommand(
  //     execute,
  //     onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
  //     onCompleted: (cover) {
  //       if (!mounted) return;
  //
  //       showDialog(
  //         context: context,
  //         builder: (_) => CoverResultPopup(cover: cover),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _topNavBar(),
                        Expanded(
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: TabBarView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CropGridViewer.preview(
                                              controller: _controller),
                                          AnimatedBuilder(
                                            animation: _controller.video,
                                            builder: (_, __) => AnimatedOpacity(
                                              opacity:
                                                  _controller.isPlaying ? 0 : 1,
                                              duration: kThemeAnimationDuration,
                                              child: GestureDetector(
                                                onTap: _controller.video.play,
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration:
                                                      const BoxDecoration(
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
                                      CoverViewer(controller: _controller)
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 200,
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    children: [
                                      Center(
                                        child: Text('Trim'),
                                      ),
                                      // const TabBar(
                                      //   tabs: [
                                      //     Row(
                                      //         mainAxisAlignment:
                                      //             MainAxisAlignment.center,
                                      //         children: [
                                      //           Padding(
                                      //               padding:
                                      //                   EdgeInsets.symmetric(
                                      //                       horizontal: 20),
                                      //               child: Icon(
                                      //                 Icons.content_cut,
                                      //                 color: Colors.white,
                                      //               )),
                                      //           Text(
                                      //             'Trim',
                                      //             style: TextStyle(
                                      //                 color: Colors.white),
                                      //           )
                                      //         ]),
                                      //
                                      //   ],
                                      // ),
                                      Expanded(
                                        child: TabBarView(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: _trimSlider(),
                                            ),
                                            _coverSelection(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _isExporting,
                                  builder: (_, bool export, Widget? child) =>
                                      AnimatedSize(
                                    duration: kThemeAnimationDuration,
                                    child: export ? child : null,
                                  ),
                                  child: AlertDialog(
                                    title: ValueListenableBuilder(
                                      valueListenable: _exportingProgress,
                                      builder: (_, double value, __) => Text(
                                        "Exporting video ${(value * 100).ceil()}%",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _topNavBar() {
    TextEditingController textEditingController = TextEditingController();
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.exit_to_app,
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
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(
                  Icons.rotate_left,
                  color: Colors.white,
                ),
                tooltip: 'Rotate unclockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(
                  Icons.rotate_right,
                  color: Colors.white,
                ),
                tooltip: 'Rotate clockwise',
              ),
            ),
            // Expanded(
            //   child: IconButton(
            //     onPressed: () =>
            //         Navigator.push(
            //       context,
            //       MaterialPageRoute<void>(
            //         builder: (context) => CropPage(controller: _controller),
            //       ),
            //     ),
            //     icon: const Icon(Icons.crop,color:Colors.white),
            //     tooltip: 'Open crop screen',
            //   ),
            // ),
            const VerticalDivider(
              endIndent: 22,
              indent: 22,
              color: Colors.white,
            ),
            Expanded(
                child: TextButton(
              child: Text("Save"),
              onPressed: () async {
                String command =
                    '-i ${widget.file.path} -ss ${_controller.startTrim.inSeconds} -t ${_controller.endTrim.inSeconds - _controller.startTrim.inSeconds} -c copy /storage/emulated/0/Download/${DateTime.now().microsecond}trim.mp4';
                await FFmpegKit.execute(command).then((session) async {
                  ReturnCode? variable = await session.getReturnCode();

                  if (variable?.isValueSuccess() == true) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Video Trimmed in Local Storage in Downloads")));
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => SelectImageScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Some Error Occured")));
                    List<Log> errors = await session.getAllLogs();
                    for (int j = 0; j < errors.length; j++) {
                      print(errors[j].getMessage());
                    }
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => SelectImageScreen()));
                  }
                });
                // showDialog(context: context, builder: (context){
                //   return  Center(
                //     child: InkWell(
                //       onTap: () async {
                //
                //       },
                //       child: Container(
                //         height: 200,
                //         child:  Text('Save to Download Folder')
                //         // AlertDialog(
                //         //
                //         //   title: Text("Name of The Edited Video"),
                //         //   content: Column(
                //         //     children: [
                //         //       TextField(
                //         //         controller: textEditingController,
                //         //       ),
                //         //       SizedBox(height: 40,),
                //         //       Center(
                //         //         child: ElevatedButton(
                //         //           onPressed: () async {
                //         //             print(widget.file.path);
                //         //
                //         //           },
                //         //           child: Text('Save to Download'),
                //         //         ),
                //         //       )
                //         //     ],
                //         //   ),
                //         // ),
                //       ),
                //     ),
                //   );
                // });
              },
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

  Widget _coverSelection() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _controller,
            size: height + 10,
            quantity: 8,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
