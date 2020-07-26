import 'package:flutter/material.dart';
import 'package:pika_joe/model/user.dart';
import 'package:pika_joe/screens/authenticate/authenticate.dart';
import 'package:pika_joe/screens/home/home.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final user = Provider.of<User>(context);

    //return either Home or Authenticate widget
    if(user == null) {
      return Authenticate();
    } else {
      return Home();
    }
  }
}