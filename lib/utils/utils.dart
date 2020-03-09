import 'dart:math';

import 'package:html_unescape/html_unescape.dart';
import 'package:rebeat_app/utils/info.dart';
import 'package:rebeat_app/youtube_api/youtube.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class TextUtils {
  static String toText(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours == 0
        ? "$twoDigitMinutes:$twoDigitSeconds"
        : "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  static int toDuration(String formattedText){
    var list = formattedText.split(":");
    switch(list.length){
      case 2: return ((double.parse(list[0]) * 60 * 1000) +  (double.parse(list[1]) * 1000)).round();
      case 3: return ((double.parse(list[1]) * 60 * 60 * 1000) + (double.parse(list[1]) * 60 * 1000) + (double.parse(list[2]) * 1000)).round();
      default: return 0;
    }
  }

  static String reformat(String formattedText){
    var list = formattedText.split(":");
    switch(list.length){
      case 2: return ((double.parse(list[0]) * 60 * 1000) +  (double.parse(list[1]) * 1000)).round().toString();
      case 3: return ((double.parse(list[1]) * 60 * 60 * 1000) + (double.parse(list[1]) * 60 * 1000) + (double.parse(list[2]) * 1000)).round().toString();
      default: return '0';
    }
  }

  static String reformatInSeconds(String formattedText){
    var list = formattedText.split(":");
    switch(list.length){
      case 2: return ((double.parse(list[0]) * 60) +  (double.parse(list[1]))).round().toString();
      case 3: return ((double.parse(list[1]) * 60 * 60) + (double.parse(list[1]) * 60) + (double.parse(list[2]))).round().toString();
      default: return '0';
    }
  }

  static String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class ExclusiveRandom{
  int end, exclude, tried;
  Random random;
  ExclusiveRandom(this.end, this.exclude){
    this.random = Random.secure();
    this.tried = 0;
  }

  int nextInt(){
    var randomInt = random.nextInt(end);
    return randomInt == exclude ? tried >= 10 ? randomInt : nextInt() : randomInt;
  }
}

class YoutubeHelper {
  static Future<List<RichSongInfo>> getResultsFromYoutube(String query) async{
    HtmlUnescape unescape = HtmlUnescape();
    YoutubeAPI api = new YoutubeAPI("YourEpikKey");
    List<YoutubeVideo> list = await api.search(query, type: "video");

    String title = query.length > 20 ? TextUtils.capitalize(query.substring(0, 20)) : TextUtils.capitalize(query);


    return list.map((e) {
      String mediumThumbnail = e.thumbnail['medium'].toString().replaceAll('{url: ', '').replaceAll(', width: 320, height: 180}', '');
      return RichSongInfo(e.id, title, unescape.convert(e.channelTitle).replaceAll("VEVO", "").replaceAll("Official", ""), mediumThumbnail, e.duration, true, mediumThumbnail);
    }).toList();
  }

  static Future<String> getVideoURL(String videoId) async{
    try{
      var first = await YoutubeExplode().getVideoMediaStream(videoId);

      var uri = first.audio.last.url;

      return uri.toString();
    }catch(exception) {
      return "";
    }
  }
}