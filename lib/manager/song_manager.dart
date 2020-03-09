import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:native_audio/native_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rebeat_app/chart/spotify_chart.dart';
import 'package:rebeat_app/utils/info.dart';
import 'package:rebeat_app/utils/utils.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  List<RichSongInfo> songs;
  List<RichArtistInfo> artists;
  List<SpotifyTrack> topSongs;
  DeezerPlaylistContainer topPlaylist;
  NativeAudio audioManager;
  bool started = false;
  bool playing;
  RichSongInfo currentSong;
  bool newSong;
  TrackEndState trackEndState;
  String streamLink;
  bool hasDownloadManagerStarted;
  RichArtistInfo currentArtist;

  AudioManager._internal(){
    this.audioManager = NativeAudio();
    this.hasDownloadManagerStarted = false;
  }

  factory AudioManager(){
    return _instance;
  }

  bool isNewSong(){
    return newSong ?? false;
  }

  Future findTopPlaylist() async{
    this.topPlaylist = await DeezerPlaylistFactory.generateContainer();
  }

  Future findTopSongs() async {
    this.topSongs = await SpotifyTrackFactory.generateTracks();
  }

  bool exists(String id){
    var a = songs.where((element) => element.id == id).length > 0;
    return a;
  }

  play(RichSongInfo info){
    if(started){
      audioManager.stop();
    }

    started = true;
    playing = true;
    audioManager.play(info.path, title: info.title, artist: info.artist, imageUrl: info.image ?? 'https://i.imgur.com/Z5LSRD9l.jpg');
  }

  playUrl(String track, artist, imageUrl){
    if(started){
      audioManager.stop();
    }

    started = true;
    playing = true;

    audioManager.play(streamLink, title: track, artist: artist, imageUrl: imageUrl);
  }

  Future refresh() async{

  }

  serialize() async{
    var dir = await getExternalStorageDirectory();
    var songsDir = Directory('${dir.path}/songs')..create();
    var file = File("${songsDir.path}/bytes_songs.json")..create();
    file.writeAsString(json.encode(songs.map((e) => e.toJson()).toList()));
  }

  pauseOrPlay(){
    if(playing){
      audioManager.pause();
      this.playing = false;
    }else{
      audioManager.resume();
      this.playing = true;
    }
  }

  Future findArtists() async{
    if(artists == null){
      List<RichArtistInfo> filteredArtists = [];
      for (var entry in songs) {
        if(filteredArtists.where((element) => element.name == entry.artist).length > 0){
          continue;
        }


        filteredArtists.add(RichArtistInfo(entry.artist, entry.artistImage, songs.where((element) => element.artist == entry.artist).map((e) => RichSongInfo(e.id, e.title, e.artist, e.image, e.duration, false, e.artistImage, path: e.path)).toList()));
      }

      this.artists  = filteredArtists;
    }
  }

  Future findSongs() async {
    var dir = await getExternalStorageDirectory();
    var songsDir = Directory('${dir.path}/songs')..createSync();
    var file = File("${songsDir.path}/bytes_songs.json");

    if(!file.existsSync()) {
      var permissionHandler = PermissionHandler();
      Map<PermissionGroup, PermissionStatus> permissions = await permissionHandler.requestPermissions([PermissionGroup.storage]);
      switch(permissions[PermissionGroup.storage]){
        case PermissionStatus.granted:
          const platform = const MethodChannel('it.auties.query/song');
          final String jsonString = await platform.invokeMethod('getSongs');
          print("Value: $jsonString");
          this.songs = RichSongContainer.fromJson(json.decode(jsonString)).songs;
          file.createSync();
          serialize();
          break;
      }

    }else{
      var data = file.readAsStringSync();
      if(data == null || data == ''){
        this.songs = [];
      }else{
        Iterable iterable = json.decode(data);
        this.songs = iterable.map((e) => RichSongInfo.fromJson(e)).toList();
      }
    }
  }

  next(){
    int current = songs.indexOf(currentSong);

    int next = current + 1 == songs.length ? 0 : current + 1;

    currentSong = songs[next];
  }


  first(){
    currentSong = songs.first;
  }

  last(){
    currentSong = songs.last;
  }

  shuffle(){
    currentSong = songs[ExclusiveRandom(songs.length, songs.indexOf(currentSong)).nextInt()];
  }

  previous(){
    int current = songs.indexOf(currentSong);
    int previous = current - 1 < 0 ? songs.length - 1 : current - 1;

    currentSong = songs[previous];
  }
}

enum TrackEndState{
  next, repeat, shuffle
}