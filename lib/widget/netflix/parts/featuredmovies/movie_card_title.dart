import 'package:flutter/material.dart';

class MovieCardTitle extends Positioned {

  final String title;

  MovieCardTitle({this.title}) : super(
    left: 30.0,
    bottom: 40.0,
    child: Container(
      width: 250.0,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      )
    )
  );
}