import 'package:flutter/material.dart';
import 'package:pika_joe/styles/constants.dart';

class ForgotPasswordButton extends Container {
  ForgotPasswordButton() : super(
    alignment: Alignment.centerRight,
    child: FlatButton(
      onPressed: () => print('Forgot Password Button Pressed'),
      padding: EdgeInsets.only(right: 0.0),
      child: Text(
        'Forgot Password?',
        style: kLabelStyle,
      ),
    ),
  );
}