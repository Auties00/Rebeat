import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screen_scaler/flutter_screen_scaler.dart';
import 'package:rebeat_app/manager/song_manager.dart';
import 'package:rebeat_app/utils/info.dart';


class SongScroller extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var scale = new ScreenScaler()..init(context);
    var _manager = AudioManager();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: SizedBox(
        height: scale.getHeight(26),
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _manager.songs.length,
            itemBuilder: (context, index)  {
              RichSongInfo info = _manager.songs[index];
              var widget = info.image != null ? Image.file(File(info.image), fit: BoxFit.fill) : Image.asset('assets/images/artist.jpg', fit: BoxFit.fill);
              return InkWell(
                onTap: () {
                  bool newValue;
                  if(_manager.currentSong == null){
                    newValue = true;
                  }else{
                    newValue = _manager.currentSong.id != info.id;
                  }

                  if(newValue){
                    _manager.currentSong = info;
                    _manager.newSong = newValue;
                  }

                  Navigator.pushNamed(context, "/player");
                },
                child: SizedBox(
                  width: scale.getWidth(55),
                  height: scale.getWidth(55),
                  child: Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                      child: widget
                  ),
                ),
              );
            }
        ),
      ),
    );
  }
}