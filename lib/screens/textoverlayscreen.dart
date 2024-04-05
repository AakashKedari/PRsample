import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoOverlayScreen extends StatefulWidget {
  @override
  _VideoOverlayScreenState createState() => _VideoOverlayScreenState();
}

class _VideoOverlayScreenState extends State<VideoOverlayScreen> {
  late VideoPlayerController _controller;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File('/storage/emulated/0/Download/famtext.mp4'))
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(true);
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Overlay'),
      ),
      body: Center(
        child: GestureDetector(
          onTapDown: _handleTap,
          child: Stack(
            children: [
              _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : Container(),
              if (_tapPosition != null)
                Positioned(
                  left: _tapPosition!.dx,
                  top: _tapPosition!.dy,
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.red,
                    child: Center(
                      child: Text(
                        'X: ${_tapPosition!.dx.toStringAsFixed(2)}, Y: ${_tapPosition!.dy.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

