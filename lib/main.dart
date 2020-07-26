import 'package:flutter/material.dart';
import 'package:pika_joe/screens/wrapper.dart';
import 'package:pika_joe/services/auth.dart';
import 'package:provider/provider.dart';

import 'model/user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamProvider<User>.value(
      value: AuthService().user,
      child: MaterialApp(
        home: Wrapper(),
      )
    );
  }
}