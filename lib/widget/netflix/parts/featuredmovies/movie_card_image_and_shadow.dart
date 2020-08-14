import 'package:flutter/material.dart';

class MovieCardImageAndShadow extends Center {

  final String imageUrl;

  MovieCardImageAndShadow({this.imageUrl}) : super(
    child: Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0.0, 4.0),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Center(
        child: Hero(
          tag: imageUrl,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image(
              image: AssetImage(imageUrl),
              height: 220.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    )
  );
}