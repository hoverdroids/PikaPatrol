import 'package:flutter/material.dart';
import 'package:pika_joe/styles/constants.dart';

class EmailEntry extends StatelessWidget {

  final bool showLabel;

  EmailEntry({this.showLabel = true}) : super();

  @override
  Widget build(BuildContext context) {

    var children = <Widget>[];
    if (showLabel) {
      children.add(_buildLabelText());
      children.add(_buildSpacer());
    }
    children.add(_buildEmailEditText());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildLabelText() {
    return Text(
      'Email',
      style: kLabelStyle,
    );
  }

  Widget _buildSpacer() {
    return SizedBox(height: 10.0);
  }

  Widget _buildEmailEditText() {
    return Container(
      alignment: Alignment.centerLeft,
      decoration: kBoxDecorationStyle,
      height: 60.0,
      child: TextField(
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'OpenSans',
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(top: 14.0),
          prefixIcon: Icon(
            Icons.email,
            color: Colors.white,
          ),
          hintText: 'Enter your Email',
          hintStyle: kHintTextStyle,
        ),
      ),
    );
  }
}