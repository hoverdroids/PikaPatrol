import 'package:flutter/material.dart';
import 'package:pika_joe/screens/authenticate/sign_in.dart';
import 'package:pika_joe/screens/home/home.dart';
import 'package:pika_joe/screens/home/home_screen.dart';
import 'dart:async';

import 'package:shimmer/shimmer.dart';

class PikaPatrolSplashScreen extends StatefulWidget {
  @override _PikaPatrolSplashScreenState createState() => _PikaPatrolSplashScreenState();
}

class _PikaPatrolSplashScreenState extends State<PikaPatrolSplashScreen> {

  @override
  void initState() {
    super.initState();

    _mockCheckForSession().then(
      (status) {
          if (status) {
            _navigateToHome();
          } else {
            _navigateToLogin();
          }
        }
    );
  }

  Future<bool> _mockCheckForSession() async {
    await Future.delayed(Duration(milliseconds: 3000), () {});

    return true;
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (BuildContext context) => HomeScreen()
        )
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (BuildContext context) => SignIn()
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Opacity(
                opacity: 0.5,
                child: Image.asset('assets/img/bg.png')
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
      ),
    );
  }
}