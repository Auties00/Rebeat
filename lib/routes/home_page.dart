import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rebeat_app/manager/song_manager.dart';
import 'package:rebeat_app/search/search_delegate.dart';
import 'package:rebeat_app/utils/info.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin{
  AudioManager _manager;
  bool _ready;
  bool _error;
  int _lastSize;

  @override
  void initState() {
    this._manager = AudioManager();
    this._ready = _manager.songs != null && _manager.artists != null && _lastSize == _manager.songs.length;
    this._error = false;

    if(!_ready) {
      _initFiles();
    }

    super.initState();
  }

  _initFiles() {
    _manager.findSongs().then((value) => _manager.findArtists()).then((value) => _manager.findTopSongs()).then((value) {
      setState(() {
        this._lastSize = _manager.songs.length;
        this._ready = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if(this._error){
      return Center(
          child: Text('Please check your internet connection!')
      );
    }

    if (_ready) {
      return SafeArea(
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (scroll) {
            scroll.disallowGlow();
            return true;
          },

          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text("Music", style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 30.0),
                            textAlign: TextAlign.start),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                          child:RawMaterialButton(
                            onPressed: () {
                              showSearch(context: context, delegate: SearchBarDelegate());
                            },
                            child: new Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            shape: new CircleBorder(),
                            elevation: 0,
                            fillColor: Colors.black,
                            padding: const EdgeInsets.all(0.0),
                          ),
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text("${_manager.songs.length} songs have been found",
                        style: TextStyle(fontWeight: FontWeight.w200, fontSize: 14.0),
                        textAlign: TextAlign.start),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, left: 14.0, right: 14.0),
                    child: Container(
                        height: 150,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        decoration: BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(10.0)),
                        child: Image.asset('assets/images/drake.jpg', fit: BoxFit.fill)
                    ),
                  ),

                  SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text("New Songs", style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 30.0),
                            textAlign: TextAlign.start),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Text("See all >", style: TextStyle(fontWeight: FontWeight.w100, fontSize: 14.0), textAlign: TextAlign.start),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 220,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, left: 14.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (BuildContext context, int index){
                          return InkWell(
                            onTap: () {
                              _manager.currentSong = RichSongInfo(_manager.topSongs[index].id, _manager.topSongs[index].title, _manager.topSongs[index].artist, _manager.topSongs[index].imageUrl, '05:00', true, _manager.topSongs[index].imageUrl);
                              _manager.newSong = true;
                              Navigator.pushNamed(context, "/player");
                            },

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 150,
                                  child: Card(
                                    semanticContainer: true,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                                    shadowColor: Colors.grey.withOpacity(0.4),
                                    child: CachedNetworkImage(
                                      imageUrl: _manager.topSongs[index].imageUrl,
                                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => Icon(Icons.error),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 7.5, top: 5.0),
                                  child: Text(_manager.topSongs[index].title, style: TextStyle(fontWeight: FontWeight.w500)),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 7.5, top: 1.0),
                                  child: Text(_manager.topSongs[index].artist, style: TextStyle(fontWeight: FontWeight.w200, fontSize: 12)),
                                )
                              ],
                            ),
                          );
                        },

                        itemCount: _manager.topSongs.length,
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text("Local Songs", style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 30.0),
                            textAlign: TextAlign.start),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Text("See all >", style: TextStyle(fontWeight: FontWeight.w100, fontSize: 14.0), textAlign: TextAlign.start),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: SizedBox(
                      height: (_manager.songs.length * 72.5),
                      child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        itemBuilder: (BuildContext context, int index){
                          return InkWell(
                            onTap: () {
                              bool newValue;
                              if(_manager.currentSong == null){
                                newValue = true;
                              }else{
                                newValue = _manager.currentSong.id != _manager.songs[index].id;
                              }

                              if(newValue){
                                _manager.currentSong = _manager.songs[index];
                                _manager.newSong = newValue;
                              }

                              Navigator.pushNamed(context, "/player");
                            },
                            child: ListTile(
                              leading: SizedBox(
                                width: 55,
                                height: 55,
                                child: Card(
                                  semanticContainer: true,
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  child: _manager.songs[index].image == null ? Image.asset('assets/images/artist.jpg', fit: BoxFit.fill) : Image.file(File(_manager.songs[index].image), fit: BoxFit.fill),
                                ),
                              ),

                              title: Text(_manager.songs[index].title, style: TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(_manager.songs[index].artist, style: TextStyle(fontWeight: FontWeight.w200, fontSize: 12)),
                              trailing: IconButton(
                                padding: EdgeInsets.all(0),
                                onPressed: () {

                                },
                                icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                              ),
                            ),
                          );
                        },

                        itemCount: _manager.songs.length,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
          child: CircularProgressIndicator()
      );
    }
  }
}