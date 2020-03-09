import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rebeat_app/routes/home_page.dart';
import 'package:rebeat_app/routes/player_page.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder> {
        "/home": (_) => HomePage(),
        "/player": (_) => PlayerPage(),
      },
      initialRoute: "/home",
      title: 'Rebeat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(color: Colors.white)
      ),
    );
  }
}
