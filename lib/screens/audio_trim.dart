import 'dart:developer';
import 'dart:io';

// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/log.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
// import 'package:ffmpeg_kit_flutter/session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/screens/splash_screen.dart';
import 'package:video_editor/video_editor.dart';
import '../audio_trimmer/trim_area_properties.dart';
import '../audio_trimmer/trim_editor_properties.dart';
import '../audio_trimmer/trim_viewer.dart';
import '../audio_trimmer/trimmer.dart';
import '../audio_trimmer/duration_style.dart';
import 'audio_trimmer_screen.dart';

class AudioSelector extends StatefulWidget {
  final bool isCollage;
  final String inputVideo;
  final double aspectratio;
  const AudioSelector({super.key, required this.isCollage, required this.inputVideo, required this.aspectratio});

  @override
  State<AudioSelector> createState() => _AudioSelectorState();
}

class _AudioSelectorState extends State<AudioSelector> {

  double _rightSliderVolLvl = 0.5;
  double _leftSliderVolLvl = 0.5;
  final Trimmer _trimmer = Trimmer();
  late final VideoEditorController _controller = VideoEditorController.file(File(widget.inputVideo),
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 20),
  );
  late String globalAudiofilePath ;
  double _startValue = 0.0;
  double _endValue = 20.0;

  @override
  void initState(){
    super.initState();
    pickCollageAudioFile();
  }

  void pickCollageAudioFile() async {
    Directory directory = await getTemporaryDirectory();

    try {
      // FilePickerResult? pickedFiles = await FilePicker.platform
      //     .pickFiles(allowMultiple: false, type: FileType.audio);
      //
      // if (pickedFiles != null) {
      //   // Get the first selected file
      //   final file = File(pickedFiles.files.first.path!);
      //
      //   final String newFilePath =
      //       '${directory.path}/copied_audio.mp3';
      //
      //   await file.copy(newFilePath);

        await _trimmer.loadAudio(audioFile: File('/storage/emulated/0/Download/stomps.mp3'));
        setState(() {

        });

        String outputPath = '${directory.path}/audtemporary.mp4';

        // String command =
        //     " -i ${widget.inputVideo} -i $newFilePath -filter_complex '[1:a]volume=0.5[a]' -map 0:v -map '[a]' -c:v copy -b:v 10M -c:a aac -y $outputPath";
        //
        // await FFmpegKit.execute(command).then((session) async {
        //   ReturnCode? variable = await session.getReturnCode();
        //
        //   if (variable?.isValueSuccess() == true) {
        //     ///assigning audioFilePath the picked audio path to adjust volumes
        //     // globalAudiofilePath = newFilePath;
        //     print('Video conversion successful');
        //     setState(() {
        //       _controller = VideoEditorController.file(File(outputPath),
        //           minDuration: const Duration(seconds: 1),
        //           maxDuration: Duration(seconds: 20 + 2));
        //       _controller
        //           .initialize(aspectRatio: widget.aspectratio)
        //           .then((_) => setState(() {
        //       }));
        //     });
        //   } else {
        //
        //     ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('Operation Failed!!!')));
        //     final List<Log> info = await session.getAllLogs();
        //     for (int i = 0; i < info.length; i++) {
        //       print(info[i].getMessage());
        //     }
        //   }
        // });
      // }
    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error Loading File')));
      print('Error picking files: $e');
    }
  }

  // Future<void> adjustVolume(double level) async {
  //
  //   Directory directory = await getTemporaryDirectory();
  //   String big = level.toStringAsFixed(2);
  //   double? finallvl = double.tryParse(big);
  //   ScaffoldMessenger.of(context)
  //       .showSnackBar(SnackBar(content: Text(finallvl.toString())));
  //
  //   // String videoPath = filterFlag == -1 ? toSavePath : filteredToSavePath;
  //   String singleAudAdjustedPath = '${directory.path}/clgaudtemporary.mp4';
  //
  //   String commandtoExecute =
  //       " -i ${widget.inputVideo} -i $globalAudiofilePath -filter_complex '[1:a]volume=$finallvl[a]' -map 0:v -map '[a]' -c:v copy -c:a aac -y $singleAudAdjustedPath";
  //
  //   // log("Adjust Volume Command : ${commandtoExecute}");
  //   FFmpegKit.execute(commandtoExecute).then((session) async {
  //     ReturnCode? variable = await session.getReturnCode();
  //
  //     if (variable?.isValueSuccess() == true) {
  //       print('Video conversion successful');
  //
  //       _controller = VideoEditorController.file(
  //           File('${directory.path}/clgaudtemporary.mp4'),
  //           minDuration: const Duration(seconds: 1),
  //           maxDuration: Duration(seconds: widget.videoDuration + 2));
  //       _controller
  //           .initialize(aspectRatio: aspectratio)
  //           .then((value) => setState(() {
  //         audioLoading = false;
  //       }));
  //     } else {
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Error Adjusting Volume')));
  //       final List<Log> info = await session.getAllLogs();
  //       for (int i = 0; i < info.length; i++) {
  //         print(info[i].getMessage());
  //       }
  //     }
  //   });
  // }
  //
  // Future<void> adjustVolumefortwoAudios(
  //     double primaryAudLvl, double secondaryAudLvl) async {
  //   String big = primaryAudLvl.toStringAsFixed(2);
  //   double? primary = double.tryParse(big);
  //   String big2 = secondaryAudLvl.toStringAsFixed(2);
  //   double? secondary = double.tryParse(big2);
  //   Directory directory = await getTemporaryDirectory();
  //
  //   try {
  //
  //     // filterFlag == -1 ? toSavePath : filteredToSavePath;
  //     final String audioPath = globalAudiofilePath;
  //     // String outputPath =
  //     //     '${directory.path}/twoaudtemporary.mp4'; // Path to save the resulting video file
  //     String doubleAudAdjustedPath = '${directory.path}/twoaudtemporary.mp4';
  //     final arguments = [
  //       '-y',
  //       '-i',
  //       widget.inputVideo,
  //       '-i',
  //       audioPath,
  //       '-filter_complex',
  //       '[0:a]volume=${primary}[a1];[1:a]volume=${secondary}[a2];[a1][a2]amix=inputs=2:duration=first[aout]',
  //       '-map',
  //       '0:v',
  //       '-map',
  //       '[aout]',
  //       '-c:v',
  //       'copy',
  //       doubleAudAdjustedPath
  //     ];
  //
  //     for (int i = 0; i < arguments.length; i++) {
  //       print(arguments[i]);
  //     }
  //
  //     Session session = await FFmpegKit.executeWithArguments(arguments);
  //     ReturnCode? variable = await session.getReturnCode();
  //
  //     if (variable!.isValueSuccess()) {
  //       FFmpegKit.cancel(session.getSessionId());
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text("Volume Conversion Success"),
  //         duration: Duration(seconds: 1),
  //       ));
  //
  //       /// Sort this out later for Video Saving Purpose
  //       // if (filterFlag == -1) {
  //       //   toSavePath = outputPath;
  //       // } else {
  //       //   filteredToSavePath = outputPath;
  //       // }
  //       // globalAudiofilePath = audioPath;
  //       _controller.dispose();
  //
  //       audioLoading = false;
  //       _controller = VideoEditorController.file(
  //           File('${directory.path}/twoaudtemporary.mp4'),
  //           minDuration: const Duration(seconds: 1),
  //           maxDuration: Duration(seconds: widget.videoDuration + 2));
  //       _controller
  //           .initialize(aspectRatio: aspectratio)
  //           .then((_) => setState(() {
  //
  //       }));
  //     } else {
  //
  //       // log('Dual Audio Failed');
  //       final List<Log> info = await session.getAllLogs();
  //       for (int i = 0; i < info.length; i++) {
  //         print(info[i].getMessage());
  //       }
  //       FFmpegKit.cancel(session.getSessionId());
  //     }
  //   } catch (e) {
  //
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('Error Loading File')));
  //     print('Error picking files: $e');
  //   }
  // }
  //
  // void pickAudioForRealVideo() async {
  //   Directory directory = await getTemporaryDirectory();
  //   File? audioFile;
  //
  //   try {
  //     FilePickerResult? pickedFile = await FilePicker.platform
  //         .pickFiles(allowMultiple: false, type: FileType.audio);
  //
  //     // Get the first selected file
  //     audioFile = File(pickedFile!.files.first.path!);
  //
  //     // Define a new file path in the cache directory
  //     final String newFilePath =
  //         '${directory.path}/copied_audio.mp3'; // You can change the file extension as per your audio file type
  //
  //     // Copy the file to the cache directory
  //     await audioFile.copy(newFilePath);
  //
  //     // filterFlag == -1 ? toSavePath : filteredToSavePath;
  //     final String audioPath = newFilePath;
  //     String outputPath =
  //         '${directory.path}/dualaudtemporary.mp4'; // Path to save the resulting video file
  //
  //     final arguments = [
  //       '-y',
  //       '-i',
  //       widget.inputVideo,
  //       '-i',
  //       audioPath,
  //       '-filter_complex',
  //       '[0:a]volume=1.0[a1];[1:a]volume=1.0[a2];[a1][a2]amix=inputs=2:duration=first[aout]',
  //       '-map',
  //       '0:v',
  //       '-map',
  //       '[aout]',
  //       '-c:v',
  //       'copy',
  //       '-c:a',
  //       'aac',
  //       '-strict',
  //       'experimental',
  //       outputPath
  //     ];
  //
  //     Session session = await FFmpegKit.executeWithArguments(arguments);
  //     ReturnCode? variable = await session.getReturnCode();
  //
  //     if (variable!.isValueSuccess()) {
  //       ScaffoldMessenger.of(context)
  //           .showSnackBar(const SnackBar(content: Text("Audio Success")));
  //       // globalAudiofilePath = audioFile!.path;
  //       print('Custom audio added successfully');
  //
  //       globalAudiofilePath = audioPath;
  //
  //       _controller = VideoEditorController.file(File(outputPath),
  //           minDuration: const Duration(seconds: 1),
  //           maxDuration: Duration(seconds: widget.videoDuration + 2));
  //       _controller
  //           .initialize(aspectRatio: aspectratio)
  //           .then((_) => setState(() {
  //
  //       }));
  //     } else {
  //
  //       print('Dual Audio Failed');
  //       final List<Log> info = await session.getAllLogs();
  //       for (int i = 0; i < info.length; i++) {
  //         print(info[i].getMessage());
  //       }
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(const SnackBar(content: Text('Error Loading File')));
  //     print('Error picking files: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Audio Trimmer"),
      ),
      body: Column(
        children: [
          Expanded(

              child: CropGridViewer.preview(controller: _controller,

              )),
          Container(
            height: 150,

            child: TrimViewer(
            trimmer: _trimmer,
            viewerHeight: 100,
            maxAudioLength: const Duration(seconds: 100),
            viewerWidth: MediaQuery.of(context).size.width,
            durationStyle: DurationStyle.FORMAT_MM_SS,
            backgroundColor: Colors.red,
            barColor: Colors.white,
            durationTextStyle: TextStyle(
                color: Theme.of(context).primaryColor),
            allowAudioSelection: true,
            editorProperties: TrimEditorProperties(
              circleSize: 10,
              borderPaintColor: Colors.pinkAccent,
              borderWidth: 4,
              borderRadius: 5,
              circlePaintColor: Colors.pink.shade400,
            ),
            areaProperties:
            TrimAreaProperties.edgeBlur(blurEdges: true),
            onChangeStart: (value) => _startValue = value,
            onChangeEnd: (value) => _endValue = value,
            onChangePlaybackState: (value) {
              if (mounted) {
                // setState(() => _isPlaying = value);
              }
            },
          ),),
          Expanded(child: BgVolSetter()),
          Expanded(child: CustomVolSetter()),
        ],
      )
      // Center(
      //   child: ElevatedButton(
      //       onPressed: () async {
      //         FilePickerResult? result = await FilePicker.platform.pickFiles(
      //           type: FileType.audio,
      //           allowCompression: false,
      //         );
      //         if (result != null) {
      //           File file = File(result.files.single.path!);
      //           // ignore: use_build_context_synchronously
      //           Navigator.of(context).push(
      //             MaterialPageRoute(builder: (context) {
      //               return AudioTrimmerView(file);
      //               // return SplashScreen();
      //             }),
      //           );
      //         }
      //       },
      //       child: const Text("Select File")),
      // ),
    );
  }

  Widget BgVolSetter() {
    return RotatedBox(
      quarterTurns: 0,
      child: Slider(

        // allowedInteraction: SliderInteraction.values.single,
        label: 'Volume Level',
        thumbColor: Colors.red,
        value: _rightSliderVolLvl,
        min: 0.0,
        max: 2.0,
        onChangeEnd: (newValue) {
          _rightSliderVolLvl = newValue;
          print(_rightSliderVolLvl.toString());
          // if (widget.collageFlag) {
          //   adjustVolume(_rightSliderVolLvL);
          // } else {
          //   adjustVolumefortwoAudios(_rightSliderVolLvL, _leftSliderVolLvl);
          // }
        },
        activeColor: Colors.white,
        inactiveColor: Colors.grey[300],
        onChanged: (double value) {
          setState(() {
            _rightSliderVolLvl = value;
          });
        },
      ),
    );
  }

  Widget CustomVolSetter() {
    return RotatedBox(
      quarterTurns: 0,
      child: Slider(
        // allowedInteraction: SliderInteraction.values.single,
        label: 'Volume Level',
        thumbColor: Colors.red,
        value: _leftSliderVolLvl,
        min: 0.0,
        max: 2.0,
        onChangeEnd: (newValue) {
          _leftSliderVolLvl = newValue;
          // adjustVolumefortwoAudios(_rightSliderVolLvL, _leftSliderVolLvl);
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
}

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
