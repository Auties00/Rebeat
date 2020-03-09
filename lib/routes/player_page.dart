import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rebeat_app/manager/song_manager.dart';
import 'file:///C:/Users/Ale/Desktop/Coding/Flutter/projects/rebeat_app/rebeat_app/lib/utils/custom_shape.dart';
import 'package:rebeat_app/utils/info.dart';
import 'package:rebeat_app/utils/utils.dart';

class PlayerPage extends StatefulWidget {

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  RichSongInfo _info;
  double _progress = 0.0;
  int _totalDuration;
  AudioManager _manager;
  bool _playing;
  bool _edit;
  File _cover;
  bool _ready;


  _PlayerPageState(){
    this._manager = AudioManager();
    this._info = _manager.currentSong;
    this._playing = true;
    this._totalDuration = _info.isStream ? TextUtils.toDuration(_info.duration) : double.parse(_info.duration).round();
    this._edit = true;
    this._ready =  false;
    if(_manager.trackEndState == null)  _manager.trackEndState = TrackEndState.next;

    _initPlayer();
  }

  _initPlayer() async{
    if(_info.isStream) {
      YoutubeHelper.getVideoURL(_info.id).then((value) async {
        _manager.streamLink = value;
        if (_manager.isNewSong()) {
          _manager.newSong = null;
          _cover = null;

          if (_info.isStream) {
            _manager.playUrl(_info.title, _info.artist, _info.image);
          }

          if (!_manager.playing) {
            _manager.audioManager.resume();
            _playing = true;
          }

          setState(() {
            this._ready = true;
          });
        }
      });
    }else{
      if (_manager.isNewSong()) {
        _manager.play(_info);

        _manager.newSong = null;

        if(_info.image != null) _cover = File(_info.image);

        this._ready = true;
      }

      if (!_manager.playing) {
        _manager.audioManager.resume();
        _playing = true;
      }
    }

    _manager.audioManager.onProgressChanged = (newValue) {
      setState(() {
        if(_edit) _progress = (newValue.inMilliseconds / _totalDuration);
      });
    };

    _manager.audioManager.onPaused = () {
      setState(() {
        _playing = false;
      });
    };

    _manager.audioManager.onResumed = () {
      setState(() {
        _playing = true;
      });
    };


    _manager.audioManager.onCompleted = () {
      switch(_manager.trackEndState) {
        case TrackEndState.next:
          _next();
          break;
        case TrackEndState.repeat:
          _repeat();
          break;
        case TrackEndState.shuffle:
          _shuffle();
          break;
      }
    };

    _manager.audioManager.onNext = () =>_next();
    _manager.audioManager.onPrevious = () => _previous();
  }

  _shuffle(){
    setState(() {
      _manager.shuffle();

      this._info = _manager.currentSong;
      this._progress = 0.0;
      this._totalDuration =  double.parse(_info.duration).round();
      if(_info.image != null) this._cover = File(_info.image);

      _manager.play(_info);
      if(!_playing){
        _manager.audioManager.pause();
      }

    });
  }

  _repeat(){
    setState(() {
      this._progress = 0.0;
      this._totalDuration =  double.parse(_info.duration).round();
      if(_info.image != null) this._cover = File(_info.image);

      _manager.play(_info);
      if(!_playing){
        _manager.audioManager.pause();
      }
    });
  }

  _next(){
    setState(() {
      if(_info.isStream){
        _manager.first();
      }else {
        _manager.next();
      }

      this._info = _manager.currentSong;
      this._progress = 0.0;
      this._totalDuration =  double.parse(_info.duration).round();
      if(_info.image != null) this._cover = File(_info.image);

      _manager.play(_info);
      if(!_playing){
        _manager.audioManager.pause();
      }

    });
  }

  _previous() {
    setState(() {
      if(_info.isStream){
        _manager.last();
      }else {
        _manager.previous();
      }

      this._info = _manager.currentSong;
      this._progress = 0.0;
      this._totalDuration = double.parse(_info.duration).round();
      if(_info.image != null) this._cover = File(_info.image);

      _manager.play(_info);
      if (!_playing) {
        _manager.audioManager.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.black),
        )),

        body: !_ready ? Center(
          child: CircularProgressIndicator()
        ) : SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 325,
                      height: 325,
                      child: Card(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                          child: _info.isStream && _cover == null ? _info.image == null ? Image.asset('assets/images/artist.jpg', fit: BoxFit.fill) : Image.network(_info.image, fit: BoxFit.fill) : _info.image != null ? Image.file(_cover, fit: BoxFit.fill) : Image.asset('assets/images/artist.jpg', fit: BoxFit.fill)
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.0),

                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    _info.title,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 28.0),
                  ),
                ),


                SizedBox(height: 3.0),

                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    _info.artist,
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 20.0, left: 20.0),
                  child: Column(
                    children: <Widget>[
                      SliderTheme(
                        data: SliderThemeData(
                            trackShape: CustomTrackShape(),
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                            thumbColor: Colors.black,
                            activeTrackColor: Colors.black,
                            inactiveTrackColor: Colors.black38
                        ),
                        child: Slider(
                          onChanged: (newValue) {
                            setState(() {
                              _progress = newValue;
                            });
                          },

                          onChangeStart: (newValue) {
                            this._edit = false;
                          },

                          onChangeEnd: (newValue) {
                            this._edit = true;
                            setState(() {
                              _manager.audioManager.seekTo(Duration(milliseconds: (newValue * _totalDuration).round()));
                            });
                          },
                          value: _progress,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 20.0, left: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        TextUtils.toText(Duration(milliseconds: (_progress * _totalDuration).round())),
                        style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300),
                      ),

                      Text(
                        TextUtils.toText(Duration(milliseconds: _info.isStream ? TextUtils.toDuration(_info.duration).round() : int.parse(_info.duration))),
                        style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300),
                      )
                    ],
                  ),
                ),

                SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _manager.trackEndState == TrackEndState.repeat ? Colors.grey[350] : Colors.transparent),
                        child: IconButton(
                          splashColor: Colors.transparent,
                          onPressed: (){
                            setState(() {
                              _manager.trackEndState = _manager.trackEndState == TrackEndState.repeat ? TrackEndState.next : TrackEndState.repeat;
                            });
                          },

                          icon: Icon(Icons.repeat),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: IconButton(
                          onPressed: () => _previous(),
                          iconSize: 32.0,
                          icon: Icon(Icons.skip_previous),
                        ),
                      ),

                      FloatingActionButton(
                        onPressed: () => _manager.pauseOrPlay(),

                        backgroundColor: Colors.black,
                        child: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: IconButton(
                          onPressed: () => _next(),
                          iconSize: 32.0,
                          icon: Icon(Icons.skip_next),
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _manager.trackEndState == TrackEndState.shuffle ? Colors.grey[350] : Colors.transparent,),
                        child: IconButton(
                          splashColor: Colors.transparent,
                          onPressed: (){
                            setState(() {
                              _manager.trackEndState = _manager.trackEndState == TrackEndState.shuffle ? TrackEndState.next : TrackEndState.shuffle;
                            });
                          },

                          icon: Icon(Icons.shuffle),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
        )
    );
  }
}

enum PlayerState{
  unknown, loaded, paused, playing, finished, stopped
}