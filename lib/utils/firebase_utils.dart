//TODO - CHRIS - add all error codes and messages from:https://firebase.google.com/docs/auth/admin/errors
/*
const String ERROR_NO_APP = "no-app";
static const String ERROR_NO_APP_MESSAGE = "";//TODO - CHRIS - get the exact message from firebase
//too-many-requests -> reached Firebase auth quota
//operation-not-allowed -> not enabled a specific auth provider
//account-exists-with-different-credential -> i.e. use first sign in with existing provider and then link to the former auth credential
//https://firebase.google.com/docs/auth/flutter/errors
//requires-recent-login
static const String ERROR_REGISTER_NETWORK_CODE = "[firebase_auth/network-request-failed] A network error (such as timeout, interrupted connection or unreachable host) has occurred";
static const String ERROR_REGISTER_NETWORK_MESSAGE = "[firebase_auth/network-request-failed] A network error (such as timeout, interrupted connection or unreachable host) has occurred";
static const String ERROR_REGISTER_EMAIL_IN_USE = "[firebase_auth/email-already-in-use] The email address is already in use by another account";


 var bla = switch(result.exception?.code) {
      "" => 0
      _ => 1
    };

Future<void> makePhoneCall(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}*/
