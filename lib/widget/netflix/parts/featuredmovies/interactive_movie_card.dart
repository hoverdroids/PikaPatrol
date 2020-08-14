import 'package:flutter/material.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';
import 'package:pika_joe/widget/netflix/movie_screen.dart';
import 'package:pika_joe/widget/netflix/parts/featuredmovies/movie_card.dart';
import 'package:pika_joe/widget/netflix/parts/featuredmovies/movie_card_image_and_shadow.dart';

import 'movie_card_title.dart';

class MovieSelector extends AnimatedWidget {

  final int index;
  final PageController pageController;
  
  const MovieSelector({this.index, this.pageController}) : super(listenable: pageController);

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      /*----------------------------  Animate the featured movie images when the user is swiping -------- */
      animation: pageController,
      builder: (BuildContext context, Widget widget) {
        double value = 1;
        if (pageController.position.haveDimensions) {
          value = pageController.page - index;
          value = (1 - (value.abs() * 0.3) + 0.06).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 270.0,
            width: Curves.easeInOut.transform(value) * 400.0,
            child: widget,
          ),
        );
      },
      /*---------------------------- Open the movie details when the user clicks the movie image -------*/
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieScreen(movie: movies[index]),
          ),
        ),
        /*--------------------------- The card visuals -------------------------------------------*/
        child: MovieCard(imageUrl: movies[index].imageUrl, title: movies[index].title),
      ),
    );
  }
}