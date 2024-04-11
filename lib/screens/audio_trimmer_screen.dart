import 'dart:io';
import 'package:flutter/material.dart';
import '../audio_trimmer/trim_area_properties.dart';
import '../audio_trimmer/trim_editor_properties.dart';
import '../audio_trimmer/trim_viewer.dart';
import '../audio_trimmer/trimmer.dart';
import '../audio_trimmer/duration_style.dart';

class AudioTrimmerView extends StatefulWidget {
  final int time;
  final File file;

  const AudioTrimmerView(  {Key? key, required this.time, required this.file,}) : super(key: key);
  @override
  State<AudioTrimmerView> createState() => _AudioTrimmerViewState();
}

class _AudioTrimmerViewState extends State<AudioTrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _progressVisibility = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  void _loadAudio() async {
    setState(() {
      isLoading = true;
    });
    await _trimmer.loadAudio(audioFile: widget.file);
    setState(() {
      isLoading = false;
    });
  }

  _saveAudio() {
    setState(() {
      _progressVisibility = true;
    });

    _trimmer.saveTrimmedAudio(

      startValue: _startValue,
      endValue: _endValue,
      audioFileName: DateTime.now().millisecondsSinceEpoch.toString(),
      onSave: (savePath) {
        /// On pressing the Button, the path of the edited video is returned to
        /// Video_Editor_Screen
        Navigator.pop(context,savePath);
        setState(() {
          _progressVisibility = false;
        });

      },
    );
  }

  @override
  void dispose() {
    if (mounted) {
      _trimmer.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,

        body: isLoading
            ? const CircularProgressIndicator()
            : Center(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Visibility(
                        visible: _progressVisibility,
                        child: LinearProgressIndicator(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _progressVisibility ? null : () => _saveAudio(),
                        child: const Text("Trim & Apply"),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                          TrimViewer(
                            trimmer: _trimmer,
                            viewerHeight: 100,
                            maxAudioLength:  const Duration(seconds: 40),
                            viewerWidth: MediaQuery.of(context).size.width,
                            durationStyle: DurationStyle.FORMAT_MM_SS,
                            backgroundColor: Colors.green.shade500,
                            barColor: Colors.white,
                            durationTextStyle: const TextStyle(
                                color: Colors.white),
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
                                setState(() => _isPlaying = value);
                              }
                            },
                          ),
                        ),
                      ),
                      TextButton(
                        child: _isPlaying
                            ? const Icon(
                                Icons.pause,
                                size: 80.0,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.play_arrow,
                                size: 80.0,
                                color: Colors.white,
                              ),
                        onPressed: () async {
                          bool playbackState =
                              await _trimmer.audioPlaybackControl(
                            startValue: _startValue,
                            endValue: _endValue,
                          );
                          setState(() => _isPlaying = playbackState);
                        },
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
