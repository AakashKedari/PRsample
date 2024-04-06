

import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prsample/customWidgets/loading_indicators.dart';
import 'package:video_player/video_player.dart';

class VideoOverlayWidget extends StatefulWidget {

  const VideoOverlayWidget({super.key,required this.editingVidPath,required this.text,required this.textStyle});

  final String editingVidPath;
  final String text;
  final TextStyle textStyle;
  @override
  _VideoOverlayWidgetState createState() => _VideoOverlayWidgetState();
}

class _VideoOverlayWidgetState extends State<VideoOverlayWidget> {
  late VideoPlayerController _controller;
  Offset position = const Offset(100, 100); // Initial position of the draggable widget


    Future<void> applyTextOnVideo() async {

  }

  bool exportFlag = false;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.editingVidPath))
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true)
      ..play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        
        title: const Text('Drag Text'),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
                : const CircularProgressIndicator(),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: Draggable(
              feedback: Material(
                color: Colors.transparent,
                child: Text(widget.text,style: const TextStyle(fontSize: 30,color: Colors.orange)),
              ),
              onDragEnd: (details) {
                setState(() {
                  position = details.offset;
                  print(position.dx);
                  print(position.dy);
                });
              },
              child: Material(
                color: Colors.transparent,
                child: Text(widget.text,style: const TextStyle(fontSize: 30,color: Colors.orange),),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            exportFlag = true;
          });
          final x = position.dx;
          final y = position.dy;
          double widthScaleFactor = 720 / 360;
          double heightScaleFactor = 1280 / 756;
          String bigx = x.toStringAsFixed(2);
          String bigy = y.toStringAsFixed(2);
          double finalx = double.parse(bigx);
          double finaly = double.parse(bigy);
          double vidExactx = finalx * widthScaleFactor;
          double vidExacty = finaly * heightScaleFactor;
          print('FFmpeg command with x: $x, y: $y');
          Directory directory = await getTemporaryDirectory();
          String tempTextOverlayPath =
          '${directory.path}/texttemporary.mp4';
          String textApplyCommand = ' -i ${widget.editingVidPath} -vf "drawtext=text='
              "${widget.text}"
              ':fontcolor=orange:fontsize=40:x=${vidExactx+20}:y=${vidExacty+85}" -c:a copy -b:v 10M -y $tempTextOverlayPath';

          log(textApplyCommand);

          FFmpegKit.execute(textApplyCommand).then((session) async {
            ReturnCode? variable = await session.getReturnCode();

            if (variable?.isValueSuccess() == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Text Applied Successfully")));
              Navigator.pop(context,tempTextOverlayPath);
            } else {
              setState(() {});
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Text Apply Failed")));
              final List<Log> info = await session.getAllLogs();
              for (int i = 0; i < info.length; i++) {
                print(info[i].getMessage());
              }
            }
          });
        },
        tooltip: 'Apply',
        child: exportFlag ? ballClipRoateWidget() : const Icon(Icons.check),
      ),
    );
  }
}
