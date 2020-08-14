import 'package:flutter/material.dart';
import 'package:pika_joe/widget/netflix/content_scroll.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';

class MyListRow extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Column (
      children: <Widget>[
        SizedBox(height: 20.0),
        ContentScroll(
          images: myList,
          title: 'My List',
          imageHeight: 250.0,
          imageWidth: 150.0,
        ),
      ],
    );
  }
}