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
    fetchedVids = removeDuplicates(videoFiles);
    for(int k=0;k<fetchedVids.length;k++){
      print(fetchedVids[k].path);
    }
    setState(() {
      fetchedVids = videoFiles;
    });

    return videoFiles;
  }

  List<File> removeDuplicates(List<File> list) {
    // Create a set to store unique items
    Set<File> uniqueSet = {};

    // Create a new list to store unique items
    List<File> uniqueList = [];

    for (var item in list) {
      // Add item to set if it's not already present (to maintain uniqueness)
      if (!uniqueSet.contains(item)) {
        uniqueSet.add(item);
        uniqueList.add(item);
      }
    }

    return uniqueList;
  }



  List<File> fetchedVids = [];
  @override
  void initState() {
    super.initState();
    getEditedVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: fetchedVids.length == 0 ? Center(
        child: Text('Nothing Created Yet'),
      ) :  Swiper(
        scrollDirection: Axis.vertical,
        itemCount: fetchedVids.length,
        itemBuilder: (context,index){
        return VideoPlayerItem(videoFile: fetchedVids[index]);
        },
        pagination: SwiperPagination(),

      )
      // ListView.builder(
      //   shrinkWrap: true,
      //     itemCount: fetchedVids.length,
      //     itemBuilder: (context, index) {
      //   return VideoPlayerItem(videoFile: fetchedVids[index]);
      // }),
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
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
