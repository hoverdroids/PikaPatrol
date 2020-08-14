import 'package:flutter/material.dart';
import 'package:pika_joe/widget/netflix/parts/featuredmovies/movie_card_image_and_shadow.dart';
import 'package:pika_joe/widget/netflix/parts/featuredmovies/movie_card_title.dart';

class MovieCard extends Stack {

  final String imageUrl;
  final String title;

  MovieCard({this.imageUrl, this.title}) : super(
    children: <Widget>[
      MovieCardImageAndShadow(imageUrl: imageUrl),
      MovieCardTitle(title: title),
    ],
  );
}