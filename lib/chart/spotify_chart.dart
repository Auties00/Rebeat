import 'dart:convert';

import 'package:http/http.dart' as http;

class SpotifyTrack{
  String id;
  String title;
  String artist;
  String imageUrl;
  SpotifyTrack(this.id, this.title, this.artist, this.imageUrl);

  SpotifyTrack.fromJson(Map<String, dynamic> json){
    this.id = json['id'];
    this.title = json['title'];
    this.artist = json['artist'];
    this.imageUrl = json['imageUrl'];
  }
}

class SpotifyTrackFactory{
  static Future<List<SpotifyTrack>> generateTracks() async {
    var res = await http.get(Uri.http("192.168.1.30:8080", "/chart"));

    Iterable iterable = json.decode(utf8.decode(res.bodyBytes));
    return iterable.map((model)=> SpotifyTrack.fromJson(model)).toList();
  }
}

class DeezerPlaylist{
  int id;
  String title;
  int numberOfTracks;
  String coverUrl;
  DeezerPlaylist(this.id, this.title, this.numberOfTracks, this.coverUrl);

  DeezerPlaylist.fromJson(Map<String, dynamic> json){
    this.id = json['id'];
    this.title = json['title'];
    this.numberOfTracks = json['nb_tracks'];
    this.coverUrl = json['picture_big'];
  }
}

class DeezerPlaylistContainer{
  List<DeezerPlaylist> data;
  int total;

  DeezerPlaylistContainer(this.data, this.total);

  DeezerPlaylistContainer.fromJson(Map<String, dynamic> json){
    Iterable iterable = json['data'];
    this.data = iterable.map((value) => DeezerPlaylist.fromJson(value)).toList();
    this.total = json['total'];
  }
}

class DeezerPlaylistFactory{
  static Future<DeezerPlaylistContainer> generateContainer() async{
    var res = await http.get("https://api.deezer.com/chart/0/playlists");
    var result =  DeezerPlaylistContainer.fromJson(json.decode(res.body));

    return result;
  }
}