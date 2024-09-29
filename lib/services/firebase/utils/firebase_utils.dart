//TODO - CHRIS - add all error codes and messages from:https://firebase.google.com/docs/auth/admin/errors
/*
const String ERROR_NO_APP = "no-app";
static const String ERROR_NO_APP_MESSAGE = "";//TODO - CHRIS - get the exact message from firebase
//too-many-requests -> reached Firebase auth quota
//operation-not-allowed -> not enabled a specific auth provider
//account-exists-with-different-credential -> i.e. use first sign in with existing provider and then link to the former auth credential
//https://firebase.google.com/docs/auth/flutter/errors
//requires-recent-login



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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

const String PLUGIN_FIREBASE_AUTH = "firebase_auth";
const String PLUGIN_FIREBASE_STORAGE = "firebase_storage";

const String ERROR_CODE_REGISTER_EMAIL_IN_USE = "email-already-in-use";
const String ERROR_MESSAGE_REGISTER_EMAIL_IN_USE = "The email address is already in use by another account";

const String ERROR_CODE_NETWORK_REQUEST_FAILED = "network-request-failed";
const String ERROR_MESSAGE_NETWORK_REQUEST_FAILED = "A network error (such as timeout, interrupted connection or unreachable host) has occurred";

const String ERROR_CODE_NO_BUCKET = "no-bucket";
const String ERROR_MESSAGE_NO_BUCKET_DEFAULT_STORAGE = "No default storage bucket could be found. Ensure you have correctly followed the Getting Started guide.";
const String ERROR_MESSAGE_NO_BUCKET_APP_STORAGE = "No storage bucket could be found for the app. Ensure you have set the [storageBucket] on [FirebaseOptions] whilst initializing the secondary Firebase app.";

const String CUSTOM_ERROR_CODE_MIME_TYPE = "mime-type";
const String CUSTOM_ERROR_MESSAGE_MIME_TYPE = "This mime type is not allowed for the given bucket";

//region Auth Exceptions
FirebaseException createFirebaseAuthException(String code, String message) => createFirebaseException(PLUGIN_FIREBASE_AUTH, code, message);
//endregion

//region Storage Exceptions
FirebaseException createFirebaseMimeTypeException({
  String code = CUSTOM_ERROR_CODE_MIME_TYPE,
  String message = CUSTOM_ERROR_MESSAGE_MIME_TYPE
}) => createFirebaseStorageException(code, message);

FirebaseException createFirebaseNoBucketException({
  String code = ERROR_CODE_NO_BUCKET,
  String message = ERROR_MESSAGE_NETWORK_REQUEST_FAILED
}) => createFirebaseStorageException(code, message);

FirebaseException createFirebaseStorageException(String code, String message) => createFirebaseException(PLUGIN_FIREBASE_STORAGE, code, message);
//endregion

//region General Exceptions
FirebaseException createFirebaseNetworkException({
  String plugin = PLUGIN_FIREBASE_STORAGE,//I'm pretty sure this could be thrown by any plugin
  String code = ERROR_CODE_NETWORK_REQUEST_FAILED,
  String message = ERROR_MESSAGE_NETWORK_REQUEST_FAILED
}) => createFirebaseException(plugin, code, message);

FirebaseException createFirebaseException(
  String plugin,
  String code,
  String message
) => FirebaseException(plugin: plugin, code: code, message: message);
//endregion

extension FirebaseUtilsExtensions on Query<Object?> {
  Query<Object?> nullableLimit(int? limit) {
    if (limit != null) {
      return this.limit(limit);
    }
    return this;
  }
}