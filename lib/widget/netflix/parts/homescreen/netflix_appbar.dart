import 'package:flutter/material.dart';

class NetFlixAppBar extends AppBar {

  NetFlixAppBar() : super(
    backgroundColor: Colors.white,
    elevation: 0.0,
    title: Image(
      image: AssetImage('assets/images/netflix_logo.png'),
    ),
    leading: IconButton(
      padding: EdgeInsets.only(left: 30.0),
      onPressed: () => print('Menu'),
      icon: Icon(Icons.menu),
      iconSize: 30.0,
      color: Colors.black,
    ),
    actions: <Widget>[
      IconButton(
        padding: EdgeInsets.only(right: 30.0),
        onPressed: () => print('Search'),
        icon: Icon(Icons.search),
        iconSize: 30.0,
        color: Colors.black,
      ),
    ],
  );
}

