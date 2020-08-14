import 'package:flutter/material.dart';
import 'package:pika_joe/widget/netflix/parts/homescreen/featured_movies.dart';
import 'package:pika_joe/widget/netflix/parts/homescreen/movie_filters.dart';
import 'package:pika_joe/widget/netflix/parts/homescreen/my_list_row.dart';
import 'package:pika_joe/widget/netflix/parts/homescreen/netflix_appbar.dart';
import 'package:pika_joe/widget/netflix/parts/homescreen/popular_row.dart';

class NetflixHomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NetFlixAppBar(),
      body: ListView(
        children: <Widget>[
          FeaturedMovies(),
          MovieFilters(),
          MyListRow(),
          PopularRow(),
        ],
      ),
    );
  }
}
