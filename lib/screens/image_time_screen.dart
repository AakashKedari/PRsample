import 'dart:io';

// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
// import 'package:ffmpeg_kit_flutter/log.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
// import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_full/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/screens/selectfiles.dart';
import 'package:prsample/screens/video_editor_screen.dart';

import '../filters.dart';

class ImageTimer extends StatefulWidget {
  List<XFile> images;
   ImageTimer({super.key,required this.images});

  @override
  State<ImageTimer> createState() => _ImageTimerState();
}

class _ImageTimerState extends State<ImageTimer> {

  // Default duration for each image
  int defaultDuration = 3;
  bool loadingFlag = false;

  // List to hold the duration for each image
  late List<int> durations ;

  void convertImagetoVideo() async {
    Directory directory = await getTemporaryDirectory();
    String output = '${directory.path}/temporary.mp4';
    String manualImagePaths = '';

    for (int i = 0; i < widget.images.length; i++) {
      manualImagePaths = "$manualImagePaths-loop 1 -i ${widget.images[i].path} ";
    }

    // Below command to rename and create a copy of a video
    // String  commandtoExecute = '-i ${video_path} -c:v mpeg4 ${output_path}';

    //
    // String genCommand = "-hide_banner -y " +
    //     manualImagePaths +
    //     "-filter_complex " +
    //     "\"[0:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,720/1280),min(iw,720),-1)':h='if(gte(iw/ih,720/1280),-1,min(ih,1280))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream1out1][stream1out2];" +
    //     "[1:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,720/1280),min(iw,720),-1)':h='if(gte(iw/ih,720/1280),-1,min(ih,1280))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream2out1][stream2out2];" +
    //     "[2:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,720/1280),min(iw,720),-1)':h='if(gte(iw/ih,720/1280),-1,min(ih,1280))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream3out1][stream3out2];" +
    //     "[stream1out1]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=3,select=lte(n\\,90)[stream1overlaid];" +
    //     "[stream1out2]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30)[stream1ending];" +
    //     "[stream2out1]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=2,select=lte(n\\,60)[stream2overlaid];" +
    //     "[stream2out2]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30),split=2[stream2starting][stream2ending];" +
    //     "[stream3out1]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=2,select=lte(n\\,60)[stream3overlaid];" +
    //     "[stream3out2]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30)[stream3starting];" +
    //     "[stream2starting][stream1ending]blend=all_expr='if(gte(X,(W/2)*T/1)*lte(X,W-(W/2)*T/1),B,A)':shortest=1[stream2blended];" +
    //     "[stream3starting][stream2ending]blend=all_expr='if(gte(X,(W/2)*T/1)*lte(X,W-(W/2)*T/1),B,A)':shortest=1[stream3blended];" +
    //     "[stream1overlaid][stream2blended][stream2overlaid][stream3blended][stream3overlaid]concat=n=5:v=1:a=0,format=yuv420p[video]\"" +
    //     " -map [video] -fps_mode cfr " +
    //     "-c:v mpeg4 -b:v 10M -r 30 " +  // Adjust bitrate and codec settings for better quality
    //     output;

    String genCommand =
        generalCommand(widget.images.length, widget.images, directory.path,durations) + output;

    print("genCommand : ${genCommand}");
    print('ImagesCount : ${widget.images.length}');

    Future.delayed(const Duration(seconds: 1));
    await FFmpegKit.execute(
      genCommand,
    ).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        print('Video conversion successful');
        Future.delayed(const Duration(seconds: 1)).then((value) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VideoEditor(file: File(output))));
          // setState(() {
          //   loadingFlag = false;
          // });
        });
      } else {
        setState(() {
          loadingFlag = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.images.length == 1
                ? "Select Multiple Images"
                : "Operation Failed")));
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const SelectImageScreen()));
        }
        if (kDebugMode) {
          print(
              'Video conversion failed with return code: ${session.getAllLogs()})}');
        }
        List<Log> list = await session.getAllLogs();
        for (int i = 0; i < list.length; i++) {
          print(list[i].getMessage());
        }
      }
    }).catchError((error) {
      print('Error while executing FFmpeg command: $error');
    });
  }

  @override
  void initState(){
    super.initState();
    durations = List.filled(widget.images.length, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !loadingFlag ?  AppBar(
        title: Text('Image Duration'),centerTitle: true,
      ) : null,
      body: loadingFlag ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Generating',style: TextStyle(color: Colors.red),),
            CircularProgressIndicator(),
          ],
        ),
      ) :  ListView.builder(
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          // Create a new TextEditingController for each text field
          TextEditingController controller = TextEditingController(text: defaultDuration.toString());

          // Return a widget for each item in the list
          return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Image.file(File(widget.images[index].path),filterQuality: FilterQuality.high,),
                SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: TextFormField(

                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Duration (seconds)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      durations[index] = int.tryParse(value) ?? defaultDuration;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: !loadingFlag ?  FloatingActionButton(
        onPressed: () {
          setState(() {
            loadingFlag = true;
          });
          convertImagetoVideo();
        },
        child: const Icon(Icons.video_collection),
      ) : null,
      // ListView.builder(
      //     itemCount: widget.images.length,
      //     itemBuilder: (context,index) {
      //   return Column(
      //     children: [
      //       Container(
      //         decoration: BoxDecoration(
      //
      //         ),
      //         height: 300,
      //         width: 300,
      //         child: Image.file(
      //           fit: BoxFit.contain,
      //           File(widget.images[index].path)
      //         ),
      //       ),
      //       const SizedBox(height: 8.0),
      //       TextFormField(
      //         initialValue: defaultDuration.toString(),
      //         decoration: const InputDecoration(
      //           labelText: 'Duration (seconds)',
      //           border: OutlineInputBorder(),
      //         ),
      //         keyboardType: TextInputType.number,
      //         onChanged: (value) {
      //           durations[index] = int.tryParse(value) ?? defaultDuration;
      //           for(int j=0;j<widget.images.length;j++){
      //             print(durations[index]);
      //           }
      //         },
      //       ),
      //     ],
      //   );
      // }),
    );
  }
}
