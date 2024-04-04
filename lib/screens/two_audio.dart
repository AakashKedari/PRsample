import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_full/session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class VideoAudioMixScreen extends StatefulWidget {
  @override
  _VideoAudioMixScreenState createState() => _VideoAudioMixScreenState();
}

class _VideoAudioMixScreenState extends State<VideoAudioMixScreen> {
  File? _videoFile;
  File? _audioFile;
  VideoPlayerController? videoPlayerController;
  // final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? pickedFile = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.audio);
    if (pickedFile != null) {
      setState(() {
        _audioFile = File(pickedFile.files.first.path!);
      });
    }
  }

  void _showGeneratedVideo(BuildContext context) {
    if (videoPlayerController != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: VideoPlayer(videoPlayerController!)))),
      );
    }
  }

  Future<void> _generateVideo() async {
    if (_videoFile == null || _audioFile == null) {
      return;
    }

    final String videoPath = _videoFile!.path;
    final String audioPath = _audioFile!.path;
    const String outputPath = '/storage/emulated/0/Download/resultingvideo.mp4'; // Path to save the resulting video file

    final arguments = [
      '-i', videoPath,
      '-i', audioPath,
      '-filter_complex', '[0:a]volume=0.3[a1];[1:a]volume=1.0[a2];[a1][a2]amix=inputs=2:duration=first[aout]',
      '-map', '0:v',
      '-map', '[aout]',
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-strict', 'experimental',
      outputPath
    ];

    Session session = await FFmpegKit.executeWithArguments(arguments);
    ReturnCode? variable = await session.getReturnCode();

    if (variable!.isValueSuccess()) {
      print('Custom audio added successfully');
      videoPlayerController = VideoPlayerController.file(File(outputPath!));
      videoPlayerController!.initialize().then((_) {
        videoPlayerController!.play();
      });
      _showGeneratedVideo(context);

      // Show the resulting video
      // You can implement this based on your preference, e.g., using Navigator to navigate to another screen
    } else {
      print('Error adding custom audio: $session');
      final List<Log> info = await session.getAllLogs();
      for (int i = 0; i < info.length; i++) {
        print(info[i].getMessage());
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Audio Mixer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Pick Video'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickAudio,
              child: Text('Pick Audio'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateVideo,
              child: Text('Generate Video'),
            ),
          ],
        ),
      ),
    );
  }
}

