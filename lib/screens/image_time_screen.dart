import 'dart:developer';
import 'dart:io';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/screens/selectfiles.dart';
import 'package:prsample/screens/video_editor_screen.dart';
import '../filters.dart';

class ImageTimer extends StatefulWidget {
  final List<XFile> ximages;
  final List<Uint8List> images;
   const ImageTimer({super.key,required this.images,required this.ximages});

  @override
  State<ImageTimer> createState() => _ImageTimerState();
}

class _ImageTimerState extends State<ImageTimer> {

  bool loadingFlag = false;

  // List to hold the duration for each image
  late List<int> durations ;

  void convertImagetoVideo() async {
    Directory directory = await getTemporaryDirectory();
    String output = '${directory.path}/temporary.mp4';

        String genCommand =
        generalCommand(widget.ximages.length, widget.ximages, directory.path,durations) + output;

    print("genCommand : $genCommand");

    Future.delayed(const Duration(seconds: 1));
    await FFmpegKit.execute(
      genCommand,
    ).then((session) async {
      ReturnCode? variable = await session.getReturnCode();

      if (variable?.isValueSuccess() == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video Conversion Successful')));
        int totalTime = durations.fold(0, (previousValue, element) => previousValue + element);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VideoEditor(file: File(output),collageFlag: true,videoDuration: totalTime,)));

      } else {
        setState(() {
          loadingFlag = false;
        });

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
  bool cropFlag = false;

  @override
  void initState(){
    super.initState();
    durations = List.filled(widget.images.length, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !loadingFlag ?  AppBar(
        title: const Text('Images Durations (sec)'),
        centerTitle: true,
      ) : null,
      body: loadingFlag ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Generating',style: TextStyle(color: Colors.red),),
            CircularProgressIndicator(),
          ],
        ),
      ) : Stack(
        children: [
          ListView.builder(
            physics: ScrollPhysics(),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              TextEditingController controller = TextEditingController();
              controller.text = durations[index].toString();

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: (){
                      _showCropImageDialog(context, widget.images[index],index);
                      // setState(() {
                      //   cropFlag = true;
                      // });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child:  Image.file(File(widget.ximages[index].path),filterQuality: FilterQuality.high,),
                      ),
                    ),
                  ),
                  // SizedBox(
                  //   width: 200,
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(20),
                  //     child: Crop(
                  //       image: widget.images[index], onCropped: (Uint8List value) {  },
                  //     )
                  //     // Image.file(File(widget.images[index].path),filterQuality: FilterQuality.high,),
                  //   ),
                  // ),
                  SizedBox(
                    width: 100,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(

                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {

                          durations[index] = int.tryParse(value)! ;

                          for(int i=0;i<durations.length;i++){
                            print(durations[i]);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        ],
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

    );
  }

  void _showCropImageDialog(BuildContext context, Uint8List image,int imgNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        CropController cropController = CropController();
        return AlertDialog(
          title: Text('Crop Image'),
          content:  Column(
            children: [
              SizedBox(
                  width: 200,
                  height: 150,
                  child: Crop(
                    interactive: true,
                    progressIndicator:const CircularProgressIndicator(),
                      controller: cropController,
                      image: image,
                      onCropped: (cropped) async {
                        String tempDirPath = (await getTemporaryDirectory()).path;
                        // Generate a unique file name
                        String tempFileName = '${DateTime.now().microsecond}temporary';
                        File tempFile = File('$tempDirPath/$tempFileName');
                        await tempFile.writeAsBytes(cropped);

                      setState(()  {
                        log('Cropped');
                        widget.images[imgNumber] = cropped;
                        widget.ximages[imgNumber] = XFile(tempFile.path);

                      });

                  },
                  onStatusChanged: (cropStatus){
                      CropStatus.ready;
                  },
                  )),
              ElevatedButton(onPressed: (){
                cropController.crop();
                Navigator.pop(context);
              }, child: Text("Crop"))
            ],
          )
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       Navigator.of(context).pop();
          //     },
          //     child: Text('Close'),
          //   ),
          // ],
        );
      },
    );
  }
}
