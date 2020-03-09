import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RichSongInfo{
  String id;
  String title;
  String artist;
  String artistImage;
  String image;
  String path;
  String duration;
  bool isStream;
  bool isDownload;

  RichSongInfo(this.id, this.title, this.artist, this.image, this.duration, this.isStream, this.artistImage, {this.path, this.isDownload});
  
  RichSongInfo.fromJson(Map<String, dynamic> json){
    this.id = json['id'];
    this.title = json['title'];
    this.artist = json['artist'];
    this.artistImage = json['imageBig'];
    this.image = json['image'];
    this.path = json['path'];
    this.duration = json['duration'];
    this.isStream = json['isStream'];
    this.isDownload = json['isDownload'];
  }

  RichSongInfo.fromCustomJson(Map<String, dynamic> json){
    this.id = json['id'];
    this.title = json['title'];
    this.artist = json['artist'];
    this.image = json['image'];
    this.path = json['path'];
    this.duration = json['duration'];
    this.isStream = false;
    this.isDownload = false;
  }

  
  Map<String, dynamic> toJson(){
    return {
    'id' : id,
    'title' : title,
    'artist' : artist,
    'imageBig' : artistImage,
    'image' : image,
    'path' : path,
    'duration' : duration,
    'isStream' : isStream,
    'isDownload' : isDownload
    };
  }
}

class RichSongContainer{
  List<RichSongInfo> songs;

  RichSongContainer.fromJson(Map<String, dynamic> json){
    Iterable iterable = json['songs'];
    this.songs = iterable.map((e) => RichSongInfo.fromCustomJson(e)).toList();
  }
}

class RichArtistInfo{
  String name;
  String image;
  List<RichSongInfo> songs;
  RichArtistInfo(this.name, this.image, this.songs);
}

class CoverUtils{
  static var uuid = Uuid();

  static findCover(String trackName, String artist, File albumCover, File artistCover) async{
    var res = await http.get('https://api.deezer.com/search?q=${trackName}_$artist');
    var container =  CoverContainer.fromJson(json.decode(res.body));
    if(container.total == 0){
      var retry = await http.get('https://api.deezer.com/search?q=$trackName');
      container = CoverContainer.fromJson(json.decode(retry.body));
      if(container.total == 0){
        throw UnsupportedError;
      }
    }

    var data = await http.get(container.data.first.album.coverLink);
    albumCover.writeAsBytes(data.bodyBytes);

    var dataArtist = await http.get(container.data.first.artist.coverLink);
    artistCover.writeAsBytes(dataArtist.bodyBytes);
  }

  static Future<File> findCoverForStream(String trackName, String artist) async{
    var dir = await getExternalStorageDirectory();
    var songsDir = Directory('${dir.path}/temp')..createSync();
    var file = File("${songsDir.path}/${uuid.v4()}.jpg");

    var res = await http.get('https://api.deezer.com/search?q=${trackName}_$artist');
    var container =  CoverContainer.fromJson(json.decode(res.body));
    if(container.total == 0){
      var retry = await http.get('https://api.deezer.com/search?q=$trackName');
      container = CoverContainer.fromJson(json.decode(retry.body));
      if(container.total == 0){
        throw UnsupportedError;
      }
    }

    var data = await http.get(container.data.first.album.coverLink);
    file.writeAsBytes(data.bodyBytes);

    return file;
  }
}

class CoverContainer{
  List<TrackCover> data;
  int total;

  CoverContainer.fromJson(Map<String, dynamic> json){
    Iterable iterable = json['data'];
    this.data = iterable.map((e) => TrackCover.fromJson(e)).toList();
    this.total = json['total'];
  }
}

class TrackCover{
  TrackArtist artist;
  TrackAlbum album;

  TrackCover.fromJson(Map<String, dynamic> json){
    this.artist = TrackArtist.fromJson(json['artist']);
    this.album = TrackAlbum.fromJson(json['album']);
  }
}

class TrackAlbum{
  String coverLink;
  TrackAlbum.fromJson(Map<String, dynamic> json){
    this.coverLink = json['cover_big'];
  }
}

class TrackArtist{
  String coverLink;

  TrackArtist.fromJson(Map<String, dynamic> json){
    this.coverLink = json['picture_big'];
  }
}