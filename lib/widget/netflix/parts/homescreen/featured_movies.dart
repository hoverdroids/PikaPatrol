import 'package:flutter/material.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';
import 'package:pika_joe/widget/netflix/parts/homescreen/movie_selector.dart';

class FeaturedMovies extends StatefulWidget {
  _FeaturedMoviesState createState() => _FeaturedMoviesState();
}

class _FeaturedMoviesState extends State<FeaturedMovies> {

  PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1, viewportFraction: 0.8);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280.0,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemCount: movies.length,
        itemBuilder: (BuildContext context, int index) {
          return MovieSelector(index: index, pageController: _pageController,);
        },
      ),
    );
  }
}