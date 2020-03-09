import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_alert_dialog/platform_alert_dialog.dart';
import 'package:rebeat_app/manager/song_manager.dart';
import 'package:rebeat_app/utils/info.dart';
import 'package:rebeat_app/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show utf8;

class SearchBarDelegate extends SearchDelegate {
  AudioManager _manager = AudioManager();
  var unescape = HtmlUnescape();

  @override
  List<Widget> buildActions(BuildContext context) {
    return query.isNotEmpty ? [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          this.query = "";
        },
      )
    ] : [
      IconButton(
        icon: Icon(Icons.keyboard_voice),
        onPressed: () {

        },
      )
    ];
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return theme.copyWith(
      primaryColor: Colors.white,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.black),
      primaryColorBrightness: Brightness.light,
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          hintStyle: TextStyle(fontWeight: FontWeight.normal)),
      primaryTextTheme: theme.textTheme,
    );
  }

  @override
  String get searchFieldLabel => 'Search a song';


  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if(query.isEmpty){
      return Center(
        child: Text('Please enter a valid song'),
      );
    }

    _addSearchHistory();

    return FutureBuilder(
      future: YoutubeHelper.getResultsFromYoutube(query),
      builder: (BuildContext context, AsyncSnapshot<List<RichSongInfo>> snapshot) {
        if(snapshot.hasData) {
          List<RichSongInfo> data = snapshot.data;

          return ListView.builder(
              itemCount: data.length,
              itemBuilder: (BuildContext context, int itemIndex) {
                
                return InkWell(
                  onTap: () {
                    bool newSong;
                    if(_manager.currentSong == null){
                      newSong = true;
                    }else{
                      newSong = _manager.currentSong.id != data[itemIndex].id;
                    }

                    if(newSong){
                      _manager.currentSong = data[itemIndex];
                      _manager.newSong = newSong;
                      Navigator.pushNamed(context, "/player");
                    }else {
                      Navigator.pushNamed(context, "/player");
                    }
                  },
                  child: ListTile(
                    leading: Container(
                      height: 50,
                      width: 50,
                      child: Card(
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                          child: Image.network(data[itemIndex].image, fit: BoxFit.fill)
                      ),
                    ),
                    title: Text(data[itemIndex].title, overflow: TextOverflow.ellipsis),
                    subtitle: Text(data[itemIndex].artist.replaceAll('VEVO', '')),
                    trailing: SizedBox(
                      width: 25,
                      height: 25,
                      child: Align(
                        child: IconButton(
                          padding: EdgeInsets.all(0),
                          icon: Icon(_manager.exists(data[itemIndex].id) ? LineIcons.check_circle_o : LineIcons.download),
                          onPressed: () => _downloadFile(context, data[itemIndex]),
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  _downloadFile(BuildContext context, RichSongInfo info) async{
    if(_manager.exists(info.id)){
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('You have already downloaded this song!')));
      return;
    }

    if(!_manager.hasDownloadManagerStarted) {
      await FlutterDownloader.initialize();
      _manager.hasDownloadManagerStarted = true;
    }

    var path = await YoutubeHelper.getVideoURL(info.id);
    var dir = await getExternalStorageDirectory();

    var songsDir = await Directory('${dir.path}/songs').create(recursive: true);
    var coversDir = await Directory('${dir.path}/covers').create(recursive: true);

    var file = File("${songsDir.path}/${info.id}.weba");
    var artistCover = File("${coversDir.path}/${info.id}Artist.jpg");
    var albumCover = File("${coversDir.path}/${info.id}Album.jpg");

    await FlutterDownloader.enqueue(
        url: path,
        savedDir: file.parent.path,
        fileName: file.path.split("/").last,
        showNotification: true,
        openFileFromNotification: false);


    await CoverUtils.findCover(info.title, info.artist, albumCover, artistCover);
    
    _manager.songs.add(RichSongInfo(info.id, info.title, info.artist, albumCover.path, TextUtils.reformat(info.duration), false, artistCover.path, path: file.path, isDownload: true));
    await _manager.serialize();
  }

  _addSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var history = (prefs.getStringList('search_history') ?? List());
    history.add(query);
    await prefs.setStringList('search_history', history);
  }


  Future<List<String>> _searchHistory() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('search_history').reversed.toSet().toList() ?? List<String>();
  }

  Future _removeSearchHistoryEntry(String entry) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var history = (prefs.getStringList('search_history') ?? List());
    history.remove(entry);
    await prefs.setStringList('search_history', history);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return FutureBuilder(
        future: _searchHistory(),
        builder: (context, AsyncSnapshot<List<String>> snapshot) {
          if(snapshot.hasData) {
            List<String> suggestions = snapshot.data;
            return ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    this.query = suggestions[index];
                    showResults(context);
                  },

                  onLongPress: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return PlatformAlertDialog(
                          title: Text(suggestions[index]),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text('Remove from search history?')
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            PlatformDialogAction(
                              child: Text('CANCEL'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            PlatformDialogAction(
                              child: Text('REMOVE'),
                              actionType: ActionType.Preferred,
                              onPressed: () {
                                _removeSearchHistoryEntry(suggestions[index]).then((value) => Navigator.of(context).pop()).then((value) => buildSuggestions(context));
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },

                  child: ListTile(
                    leading: IconButton(
                      onPressed: () {
                        this.query = suggestions[index];
                        showResults(context);
                      },

                      icon: Icon(Icons.history),
                    ),

                    title: Text(suggestions[index]),
                  ),
                );
              },
              itemCount: suggestions.length,
            );
          }

          return Container(

          );
        }
      );
    }

    return FutureBuilder(
      future: executeRequest(query),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if(!snapshot.hasData){
          return Container(

          );
        }

        List<String> list = snapshot.data;
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () {
                this.query = list[index];
                showResults(context);
              },

              child: ListTile(
                leading: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {

                  },
                ),

                title: Text(list[index]),
              ),
            );
          },
          itemCount: list.length,
        );
      },
    );
  }

  Future<List<String>> executeRequest(String query) async {
    var res = await http.get('http://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=$query');
    String body = utf8.decode(res.bodyBytes).replaceAll('\\"', '"');
    RegExp exp = new RegExp(
      r'"(.*?)"',
      multiLine: true,
      caseSensitive: false,
      dotAll: true,
    );


    return exp.allMatches(body).map((e) => e.start + 1 == e.end - 1? body.substring(e.start, e.end - 1) : body.substring(e.start + 1, e.end - 1)).toList();
  }
}


