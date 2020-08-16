import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pika_joe/styles/constants.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/buttons/standardized_button.dart';
import 'package:pika_joe/widget/buttons/circular_button.dart';
import 'package:pika_joe/widget/forms/email_entry.dart';
import 'package:pika_joe/widget/forms/forgot_password_button.dart';
import 'package:pika_joe/widget/forms/password_entry.dart';

import 'elements/remember_me_checkbox.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  Widget _buildSignInWithText() {
    return Column(
      children: <Widget>[
        Text(
          '- OR -',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 20.0),
        Text(
          'Sign in with',
          style: kLabelStyle,
        ),
      ],
    );
  }

  Widget _buildSocialBtnRow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          CircularImageButton(
            assetImage: AssetImage('assets/img/social/facebook.jpg'),
            onButtonTapped: () => print('Login with Facebook'),
          ),
          CircularImageButton(
            assetImage: AssetImage('assets/img/social/google.jpg'),
            onButtonTapped: () => print('Login with Google'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupBtn() {
    return GestureDetector(
      onTap: () => print('Sign Up Button Pressed'),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Don\'t have an Account? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Sign Up',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF73AEF5),
                      Color(0xFF61A4F1),
                      Color(0xFF478DE0),
                      Color(0xFF398AE5),
                    ],
                    stops: [0.1, 0.4, 0.7, 0.9],
                  ),
                ),
              ),
              Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 120.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 30.0),
                      EmailEntry(),
                      SizedBox(
                        height: 30.0,
                      ),
                      PasswordEntry(),
                      ForgotPasswordButton(),
                      RememberMeCheckbox(),
                      StandardizedButton(
                        text:"Login",
                        elementSize: ElementSize.M,               //TODO
                        widthStyle: WidthStyle.MATCH_PARENT,
                        elementStyle: ElementStyle.LIGHT_ON_LIGHT,//TODO
                        emphasis: Emphasis.NONE,                  //TODO
                        shadowIntensity: ShadowIntensity.DARK,    //TODO
                        shadowSize: ShadowSize.SMALL,
                        spacingType: SpacingTypes.TOP_BOTTOM,
                        backgroundShade: BackgroundShades.LIGHT,  //TODO
                        cornerType: CornerTypes.CIRCULAR,
                      ),
                      _buildSignInWithText(),
                      _buildSocialBtnRow(),
                      _buildSignupBtn(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}