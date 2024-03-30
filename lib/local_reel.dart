import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';

import 'package:prsample/selectfiles.dart';
import 'package:video_player/video_player.dart';
// import 'package:tapioca/tapioca.dart';
import 'package:logger/logger.dart';
// import '../select_files/selectfiles.dart';

class VideoScreen extends StatefulWidget {
  final String path;

  VideoScreen(this.path);

  @override
  _VideoAppState createState() => _VideoAppState(path);
}

class _VideoAppState extends State<VideoScreen> {
  final String path;

  _VideoAppState(this.path);

  late VideoPlayerController _controller;
  // final FijkPlayer player = FijkPlayer();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(path))
      ..initialize()
    .then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          _controller.play();
        });
      });
    // player.setDataSource(path,autoPlay: true,showCover: true);
  }

  Future<void> saveVideoinDownloads() async {
    print(widget.path);
     String  command = '-i ${widget.path} -c:v mpeg4 /storage/emulated/0/Download/${DateTime.now().year.toString()}${DateTime.now().millisecond}${DateTime.now().microsecond}.mp4';
     await FFmpegKit.execute(command).then((session) async {
       ReturnCode? variable = await session.getReturnCode();

       if (variable?.isValueSuccess() == true) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video Saved in Local Storage in Downloads")));
       }
       else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Some Error Occured")));
         List<Log> errors = await session.getAllLogs();
         for(int j=0;j<errors.length;j++){
           print(errors[j].getMessage());
         }
       }
       });}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:
      Center(
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
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(onPressed: (){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VideoEditor(file: File(widget.path),)));
          }, child: Text("Trim",style: TextStyle(fontSize: 25),)),
          TextButton(onPressed: saveVideoinDownloads,
              child: Text("Save",style: TextStyle(fontSize: 25),)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}


