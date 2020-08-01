
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

final Container pikaPatrolSplashPage = Container(
  color: Colors.pink,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(
              opacity: 0.5,
              child: Image.asset('assets/img/firstImage.png')
          ),
          Shimmer.fromColors(
            period: Duration(milliseconds: 1500),
            baseColor: Color(0xff7f00ff),
            highlightColor: Color(0xffe100ff),
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Vicon",
                style: TextStyle(
                    fontSize: 90.0,
                    fontFamily: 'Pacifico',
                    shadows: <Shadow>[
                      Shadow(
                          blurRadius: 18.0,
                          color: Colors.black87,
                          offset: Offset.fromDirection(120, 12)
                      )
                    ]
                ),
              ),
            ),
          )
        ],
      ),
    ],
  ),
);