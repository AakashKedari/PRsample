import 'dart:io';
import 'dart:developer';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/log.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

String generalCommand(
    int n, List<XFile> photos, String tempDirectory, List<int> durations)  {

  int totalImageSelected = n;
  String manualImagePaths = '';

  for (int i = 0; i < photos.length; i++) {
    manualImagePaths = "$manualImagePaths-loop 1 -t 5 -i ${photos[i].path} ";
  }

  String blendFilter() {
    String blend = "";
    for (int u = 1; u < totalImageSelected; u++) {
      blend =
          "$blend[stream${u + 1}starting][stream${u}ending]blend=all_expr='if(gte(X,(W/2)*T/1)*lte(X,W-(W/2)*T/1),B,A)':shortest=1[stream${u + 1}blended];";
    }
    return blend;
  }

  String padFilter() {
    String pad = "";

    for (int k = 1; k <= totalImageSelected; k++) {
      log(durations[k-1].toString());
      if (k == 1) {
        pad =
            "$pad[stream${k}out1]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=${durations[k - 1]},select=lte(n\\,90)[stream${k}overlaid];[stream${k}out2]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30)[stream${k}ending];";
      } else if (k == totalImageSelected) {
        pad =
            "$pad[stream${k}out1]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=${durations[k - 1]},select=lte(n\\,90)[stream${k}overlaid];[stream${k}out2]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30)[stream${k}starting];";
      } else {
        pad =
            "$pad[stream${k}out1]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=${durations[k - 1]},select=lte(n\\,90)[stream${k}overlaid];[stream${k}out2]scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30),split=2[stream${k}starting][stream${k}ending];";
      }
    }
    log("Pad filter is : ${pad}");
    return pad;
  }

  String setptsFilter() {
    String setpts = '';
    for (int j = 0; j < totalImageSelected; j++) {
      setpts =
          "$setpts[$j:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,720/1280),min(iw,720),-1)':h='if(gte(iw/ih,720/1280),-1,min(ih,1280))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream${j + 1}out1][stream${j + 1}out2];";
    }

    return setpts;
  }

  String lastFilter() {
    String last = "";
    for (int i = 1; i <= totalImageSelected; i++) {
      if (i == 1) {
        last = "$last[stream${i}overlaid]";
      } else {
        last = "$last[stream${i}blended][stream${i}overlaid]";
      }
    }
    return last;
  }

  String command =
      "-hide_banner -y $manualImagePaths-filter_complex \"${setptsFilter()}${padFilter()}${blendFilter()}${lastFilter()}concat=n=${((totalImageSelected - 1) * 2) + 1}:v=1:a=0,scale=w=720:h=1280,format=yuv420p[video]\" -map [video] -fps_mode cfr -c:v mpeg4 -b:v 10M ";

  var logger = Logger();
  logger.d(command);
  return command;
}

Future<String> applyFilters(String toSavePath, int filterNumber) async {
  // Input and output paths
  final String inputPath = toSavePath;

  Directory directory = await getTemporaryDirectory();

  final String  outputPath = '${directory.path}/Filtertemporary.mp4';

  // Declare a variable to hold the output path
  String? result;

  // Command to apply pink color effect
  // ' -i ${inputPath} -vf colorbalance=rs=0.7:gs=0.9 ${outputPath}';

  final String command = filterNumber == 1
      ? ' -i $inputPath -vf rgbashift=rh=-6:gh=6 -pix_fmt yuv420p -b:v 10M -y $outputPath'
      : filterNumber == 2
          ? // Retro
          " -i $inputPath -vf curves=blue='0/0 0.5/0.58 1/1' -b:v 10M -y $outputPath"
          : filterNumber == 3 ? '-i $inputPath -vf format=gray -b:v 10M -y $outputPath' : filterNumber == 4 ? "-i $inputPath -vf 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131' -y $outputPath" :// Execute Curves
          " -i $inputPath -vf noise=alls=60:allf=t+u -b:v 10M  -y $outputPath";
  await FFmpegKit.execute(command).then((session) async {
    ReturnCode? variable = await session.getReturnCode();

    if (variable!.isValueSuccess()) {
      print('Filter applied correctly');
      result = outputPath; // Assign the output path to the variable
    } else {
      print('Error Occured');
      List<Log> list = await session.getAllLogs();
      for (int i = 0; i < list.length; i++) {
        print(list[i].getMessage());
      }
      result = ''; // Assign an empty string in case of error
    }
  });

  // Return the output path or an empty string
  return result ?? 'Returning Empty String';
}

