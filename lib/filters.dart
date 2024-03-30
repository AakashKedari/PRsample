
import 'package:image_picker/image_picker.dart';

String customImagePaths = '';
String output_path = '/storage/emulated/0/Download/ram.mp4';
int totalImageSelected = 0;

void writingCustomImagePaths (int n,List<XFile> photos){
  totalImageSelected = n;
  for (int i = 0; i < n; i++) {
    // customImagePaths += images
    customImagePaths =
        customImagePaths + "-loop 1 -i " + photos[i].path + " ";
  }
}

String setptsFilter(){
  String setpts = '';
  for(int j=0;j<totalImageSelected;j++){
    setpts = setpts + "[${j}:v]setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,640/427),min(iw,640),-1)':h='if(gte(iw/ih,640/427),-1,min(ih,427))',scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream${j+1}out1][stream${j+1}out2];";

  }
  return setpts;
}


String padFilter(){
  String pad = "";
  for (int k=1;k<=totalImageSelected;k++){
    pad = pad + "[stream${k}out1]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=3,select=lte(n\\,90)[stream${k}overlaid];" +
        "[stream${k}out2]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,trim=duration=1,select=lte(n\\,30)[stream${k}ending];";
  }
  return pad;
}

String blendFilter(){
  String blend = "";
  for (int u =1;u<totalImageSelected;u++){
    blend = blend + "[stream${u+1}starting][stream${u}ending]blend=all_expr='if(gte(X,(W/2)*T/1)*lte(X,W-(W/2)*T/1),B,A)':shortest=1[stream${u+1}blended];";
  }
  return blend;
}
// [stream1overlaid][stream2blended][stream2overlaid][stream3blended][stream3overlaid]
String lastFilter (){
  String last = "";
  for (int i=1;i<=totalImageSelected;i++){
    if (i == totalImageSelected){
      last = last + "[stream${i}overlaid]";
      break;
    }
    else {
      last = last + "[stream${i}overlaid][stream${i + 1}blended]";
    }
  }
  return last;
}

String generalCommand = "-hide_banner -y " +
    customImagePaths +
    "-filter_complex \"" +
    setptsFilter() +
    padFilter() +
    blendFilter() +
    lastFilter() + "concat=n=9:v=1:a=0,scale=w=640:h=424,format=" +
    "yuv420p" +
    "[video]\"" +
    " -map [video] -fps_mode cfr " +
    "" +
    "-c:v " +
    "mpeg4" +
    " -r 30 " +
    output_path;

String genericFunction(int numberOfStreams){
  // Try at home please today itself
  String command = "-hide_banner -y ";

// Iterate over each image stream
  for (int i = 0; i < numberOfStreams; i++) {
    String imageStream = "[input" + i.toString() + ":v]";
    String processingFilters = "setpts=PTS-STARTPTS,scale=w='if(gte(iw/ih,640/427),min(iw,640),-1)':h='if(gte(iw/ih,640/427),-1,min(ih,427))'," +
        "scale=trunc(iw/2)*2:trunc(ih/2)*2,setsar=sar=1/1,split=2[stream" + i.toString() + "out1][stream" + i.toString() + "out2];" +
        "[stream" + i.toString() + "out1]pad=width=640:height=427:x=(640-iw)/2:y=(427-ih)/2:color=#00000000,";

// Determine trimming and selection duration based on stream index
    String trimDuration;
    if (i == 0) {
      trimDuration = "3";
    } else {
      trimDuration = "2";
    }

// Add trimming and selection filters
    processingFilters += "trim=duration=" + trimDuration + ",select=lte(n\\," + (i + 1).toString() * 30 + ")";

    if (i < numberOfStreams - 1) {
      processingFilters += "[stream" + i.toString() + "overlaid];";
    } else {
      processingFilters += "[stream" + i.toString() + "ending];";
    }

    command += imageStream + processingFilters;
  }

// Combine all streams and set output options
  command += "concat=n=" + numberOfStreams.toString() + ":v=1:a=0,scale=w=640:h=424,format=yuv420p[video]\" -map [video] -fps_mode cfr " +
      "-c:v mpeg4 -r 30 " +
      output_path;

  return command;
}



