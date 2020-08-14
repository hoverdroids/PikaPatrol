
import 'package:flutter/cupertino.dart';

import 'package:pika_joe/widget/netflix/content_scroll.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';

class PopularRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column (
      children: <Widget>[
        SizedBox(height: 10.0),
        ContentScroll(
          images: popular,
          title: 'Popular',
          imageHeight: 250.0,
          imageWidth: 150.0,
        ),
      ],
    );
  }
}