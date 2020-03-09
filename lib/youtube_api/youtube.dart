//DISCLAIMER:
//This class is not my work, I had to copy it from a flutter plugin located at https://pub.dev/packages/youtube_api
//Reason: The plugin's native side isn't configured properly, so I would have had to regenerate it by forking the github repo and editing the native code
//Thanks for your understanding!

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class YoutubeAPI {
  String key;
  String type;
  String query;
  String prevPageToken;
  String nextPageToken;
  int maxResults;
  API api;
  int page;

//  Constructor
  YoutubeAPI(this.key, {String type, int maxResults: 10}) {
    page = 0;
    this.type = type;
    this.maxResults = maxResults;
    api = new API(key: this.key, maxResults: this.maxResults, type: this.type);
  }

//  For Searching on YouTube
  Future<List> search(String query, {String type}) async {
    this.query = query;
    Uri url = api.searchUri(query, type: type);
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      print(jsonData['error']);
      return [];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return [];
    List<YoutubeVideo> result = await _getResultFromJson(jsonData);
    return result;
  }

// For getting all videos from youtube channel
  Future<List> channel(String channelId, {String order}) async {
    Uri url = api.channelUri(channelId, order);
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      print(jsonData['error']);
      return [];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return [];
    List<YoutubeVideo> result = await _getResultFromJson(jsonData);
    return result;
  }

  /*
  Get video details from video Id
   */
  Future<List<YT_VIDEO>> video(List<String> videoId) async {
    List<YT_VIDEO> result = [];
    Uri url = api.videoUri(videoId);
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);

    if (jsonData == null) return [];

    int total = jsonData['pageInfo']['totalResults'] <
        jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];

    for (int i = 0; i < total; i++) {
      result.add(new YT_VIDEO(jsonData['items'][i]));
    }
    return result;
  }

  Future<List<YoutubeVideo>> _getResultFromJson(jsonData) async {
    List<YoutubeVideo> result = [];
    if (jsonData == null) return [];

    nextPageToken = jsonData['nextPageToken'];
    api.setNextPageToken(nextPageToken);
    int total = jsonData['pageInfo']['totalResults'] <
        jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];
    result = await _getListOfYTAPIs(jsonData, total);
    page = 1;
    return result;
  }

  Future<List<YoutubeVideo>> _getListOfYTAPIs(dynamic data, int total) async {
    List<YoutubeVideo> result = [];
    List<String> videoIdList = [];
    for (int i = 0; i < total; i++) {
      YoutubeVideo ytApiObj = new YoutubeVideo(data['items'][i]);
      if(ytApiObj.kind == "video")
        videoIdList.add(ytApiObj.id);
      result.add(ytApiObj);
    }
    List<YT_VIDEO> videoList = await video(videoIdList);
    await Future.forEach(videoList, (YT_VIDEO ytVideo) {
      YoutubeVideo ytAPIObj = result.singleWhere((ytAPI) => ytAPI.id == ytVideo.id, orElse: () => null);
      ytAPIObj.duration = _getDuration(ytVideo?.duration ?? "") ?? "";
    });
    return result;
  }

// To go on Next Page
  Future<List> nextPage() async {
    if(api.nextPageToken == null)
      return null;
    List<YoutubeVideo> result = [];
    Uri url = api.nextPageUri();
    print(url);
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);

    if (jsonData['pageInfo']['totalResults'] == null) return [];

    if (jsonData == null) return [];

    nextPageToken = jsonData['nextPageToken'];
    prevPageToken = jsonData['prevPageToken'];
    api.setNextPageToken(nextPageToken);
    api.setPrevPageToken(prevPageToken);
    int total = jsonData['pageInfo']['totalResults'] <
        jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];
    result = await _getListOfYTAPIs(jsonData, total);
    page++;
    if (total == 0) {
      return null;
    }
    return result;
  }

  Future<List> prevPage() async {
    if(api.prevPageToken == null)
      return null;
    List<YoutubeVideo> result = [];
    Uri url = api.prevPageUri();
    print(url);
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var jsonData = json.decode(res.body);

    if (jsonData['pageInfo']['totalResults'] == null) return [];

    if (jsonData == null) return [];

    nextPageToken = jsonData['nextPageToken'];
    prevPageToken = jsonData['prevPageToken'];
    api.setNextPageToken(nextPageToken);
    api.setPrevPageToken(prevPageToken);
    int total = jsonData['pageInfo']['totalResults'] <
        jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];
    result = await _getListOfYTAPIs(jsonData, total);
    if (total == 0) {
      return null;
    }
    page--;
    return result;
  }

//  Get Current Page
  int get getPage => page;

//  Getter and Setter for Max Result Per page
  set setmaxResults(int maxResults) => this.maxResults = maxResults;

  get getmaxResults => this.maxResults;

//  Getter and Setter Key
  set setKey(String key) => api.key = key;

  String get getKey => api.key;

//  Getter and Setter for query
  set setQuery(String query) => api.query = query;

  String get getQuery => api.query;

//  Getter and Setter for type
  set setType(String type) => api.type = type;

  String get getType => api.type;
}

String _getDuration(String duration){
  if(duration.isEmpty) return null;
  duration = duration.replaceFirst("PT", "");

  var validDuration = ["H", "M", "S"];
  if(!duration.contains(new RegExp(r'[HMS]'))){
    return null;
  }
  var hour = 0, min = 0, sec = 0;
  for(int i = 0; i< validDuration.length; i++){
    var index = duration.indexOf(validDuration[i]);
    if(index != -1){
      var valInString = duration.substring(0, index);
      var val = int.parse(valInString);
      if(i == 0) hour = val;
      else if(i == 1) min = val;
      else if(i == 2) sec = val;
      duration = duration.substring(valInString.length + 1);
    }
  }
  List buff = [];
  if(hour != 0){
    buff.add(hour);
  }
  if(min == 0){
    if(hour != 0) buff.add(min.toString().padLeft(2,'0'));
  } else {
    buff.add(min.toString().padLeft(2,'0'));
  }
  buff.add(sec.toString().padLeft(2,'0'));

  return buff.join(":");
}

//To Reduce import
// I added this here
class YoutubeVideo {
  dynamic thumbnail;
  String kind,
      id,
      publishedAt,
      channelId,
      channelurl,
      title,
      description,
      channelTitle,
      url,
      duration;

  YoutubeVideo(dynamic data) {
    thumbnail = {
      'default': data['snippet']['thumbnails']['default'],
      'medium': data['snippet']['thumbnails']['medium'],
      'high': data['snippet']['thumbnails']['high']
    };
    kind = data['id']['kind'].substring(8);
    id = data['id'][data['id'].keys.elementAt(1)];
    print(data['id'].keys.elementAt(1));
    print(id);
    url = getURL(kind, id);
    publishedAt = data['snippet']['publishedAt'];
    channelId = data['snippet']['channelId'];
    channelurl = "https://www.youtube.com/channel/$channelId";
    title = data['snippet']['title'];
    description = data['snippet']['description'];
    channelTitle = data['snippet']['channelTitle'];
  }

  String getURL(String kind, String id) {
    String baseURL = "https://www.youtube.com/";
    switch (kind) {
      case 'channel':
        return "${baseURL}channel/$id";
        break;
      case 'video':
        return "${baseURL}watch?v=$id";
        break;
      case 'playlist':
        return "${baseURL}playlist?list=$id";
        break;
    }
    return baseURL;
  }
}

class YT_VIDEO {
  String duration;
  String id;

  YT_VIDEO(dynamic data) {
    id = data['id'];
    duration = data['contentDetails']['duration'];
  }
}

class API {
  String key;
  int maxResults;
  String order;
  String safeSearch;
  String type;
  String videoDuration;
  String nextPageToken;
  String prevPageToken;
  String query;
  String channelId;
  Object options;
  static String baseURL = 'www.googleapis.com';

  API({this.key, this.type, this.maxResults, this.query});

  Uri searchUri(query, {String type}) {
    this.query = query;
    this.type = type ?? this.type;
    this.channelId = null;
    var options = getOption();
    Uri url = new Uri.https(baseURL, "youtube/v3/search", options);
    return url;
  }

  Uri channelUri(String channelId, String order) {
    this.order = order ?? 'date';
    this.channelId = channelId;
    var options = getChannelOption(channelId, this.order);
    Uri url = new Uri.https(baseURL, "youtube/v3/search", options);
    return url;
  }

  Uri videoUri(List<String> videoId) {
    int length = videoId.length;
    String videoIds = videoId.join(',');
    var options = getVideoOption(videoIds, length);
    Uri url = new Uri.https(baseURL, "youtube/v3/videos", options);
    return url;
  }

//  For Getting Getting Next Page
  Uri nextPageUri() {
    var options = this.channelId == null ? getOptions("pageToken", nextPageToken) : getChannelPageOption(channelId, "pageToken", nextPageToken);
    Uri url = new Uri.https(baseURL, "youtube/v3/search", options);
    return url;
  }

//  For Getting Getting Previous Page
  Uri prevPageUri() {
    var options = this.channelId == null ? getOptions("pageToken", prevPageToken) : getChannelPageOption(channelId, "pageToken", prevPageToken);
    Uri url = new Uri.https(baseURL, "youtube/v3/search", options);
    return url;
  }

  Object getOptions(String key, String value) {
    Object options = {
      key: value,
      "q": "${this.query}",
      "part": "snippet",
      "maxResults": "${this.maxResults}",
      "key": "${this.key}",
      "type": "${this.type}",
      "videoCategoryId": "10"
    };
    return options;
  }

  Object getOption() {
    Object options = {
      "q": "${this.query}",
      "part": "snippet",
      "maxResults": "${this.maxResults}",
      "key": "${this.key}",
      "type": "${this.type}"
    };
    return options;
  }

  Object getChannelOption(String channelId, String order) {
    Object options = {
      'channelId': channelId,
      "part": "snippet",
      'order': this.order,
      "maxResults": "${this.maxResults}",
      "key": "${this.key}",
    };
    return options;
  }

  Object getChannelPageOption(String channelId, String key, String value) {
    Object options = {
      key: value,
      'channelId': channelId,
      "part": "snippet",
      "maxResults": "${this.maxResults}",
      "key": "${this.key}",
    };
    return options;
  }

  Object getVideoOption(String videoIds, int length) {
    Object options = {
      "part": "contentDetails",
      "id": videoIds,
      "maxResults": "$length",
      "key": "${this.key}",
    };
    return options;
  }

  void setNextPageToken(String token) => this.nextPageToken = token;
  void setPrevPageToken(String token) => this.nextPageToken = token;
}