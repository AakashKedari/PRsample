import 'dart:developer';
import 'dart:io';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';

class CachedVideos extends StatefulWidget {
  const CachedVideos({super.key});

  @override
  State<CachedVideos> createState() => _CachedVideosState();
}

class _CachedVideosState extends State<CachedVideos> {
  Future<List<File>> getEditedVideos() async {
    Directory cacheDir = await getTemporaryDirectory();
    List<FileSystemEntity> files = cacheDir.listSync();
    List<File> videoFiles = files
        .where((entity) => entity is File && entity.path.endsWith('.mp4'))
        .map((entity) => File(entity.path))
        .toList();

    for(int k=0;k<videoFiles.length;k++){
      print(videoFiles[k].path);
    }

    // Remove files whose path ends with 'temp_collage.mp4'
    List<File> filteredList = videoFiles.where((file) => !file.path.endsWith('temporary.mp4')).toList();

    for(int k=0;k<filteredList.length;k++){
      print(filteredList[k].path);
    }

    setState(() {
      fetchedVids = filteredList;
    });

    return videoFiles;
  }





  List<File> fetchedVids = [];
  @override
  void initState() {
    super.initState();
    getEditedVideos();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: fetchedVids.isEmpty ? const Center(
          child: Text('Nothing Created Yet'),
        ) :  Swiper(
          loop: false,
          scrollDirection: Axis.vertical,
          itemCount: fetchedVids.length,
          itemBuilder: (context,index){
          return VideoPlayerItem(videoFile: fetchedVids[index]);
          },
          pagination: const SwiperPagination(),
      
        )
        // ListView.builder(
        //   shrinkWrap: true,
        //     itemCount: fetchedVids.length,
        //     itemBuilder: (context, index) {
        //   return VideoPlayerItem(videoFile: fetchedVids[index]);
        // }),
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final File videoFile;

  VideoPlayerItem({required this.videoFile});

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}



//
// class _VideoPlayerItemState extends State<VideoPlayerItem> {
//   late VideoPlayerController _controller;
//   late ChewieController _chewieController;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(widget.videoFile);
//     _chewieController = ChewieController(
//       videoPlayerController: _controller,
//       autoPlay: true,
//       looping: true,
//       // Other ChewieController configurations as needed
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _chewieController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           if (_controller.value.isPlaying) {
//             _controller.pause();
//           } else {
//             _controller.play();
//           }
//         });
//       },
//       child: FutureBuilder(
//         future: _controller.initialize(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             return AspectRatio(
//               aspectRatio: _controller.value.aspectRatio,
//               child: Chewie(
//                 controller: _chewieController,
//               ),
//             );
//           } else {
//             return Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }



class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile);
    _initializeVideoPlayerFuture = _controller.initialize().then((value) => _controller.play());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: SizedBox(
                height: 1280,
                width: 720,
                child: VideoPlayer(_controller),
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
