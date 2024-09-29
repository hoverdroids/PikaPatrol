import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pika_patrol/model/value_exception_pair.dart';
import 'package:pika_patrol/services/firebase/firebase_constants.dart';

import '../../model/firebase_value_exception_pair.dart';
import '../../utils/constants.dart';
import 'buckets/firebase_storage_bucket.dart';
import 'collections/firebase_firestore_collection.dart';
import 'firebase_service.dart';

class FirebaseFirestoreService extends FirebaseService {

  //region Constructors
  FirebaseFirestoreService({
    FirebaseFirestore? firebaseFirestore,
    super.useEmulator = false,
    super.emulatorHostnameOrIpAddress = Constants.LOCALHOST,
    super.emulatorPort = FirebaseConstants.EMULATOR_PORT_FIRESTORE,
    this.persistenceEnabled = true,
    this.sslEnabled = false
  }) {
    this.firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance;

    if (Platform.isAndroid && emulatorHostnameOrIpAddress == Constants.LOCALHOST) {
      emulatorHostnameOrIpAddress = Constants.LOCALHOST_ANDROID;
    }

    _applyEmulatorSettings();
    _applySettings();
  }
  //endregion

  //region Firestore
  late final FirebaseFirestore firebaseFirestore;

  FirebaseApp get app => firebaseFirestore.app;

  String get databaseURL => firebaseFirestore.databaseURL;
  //endregion

  //region Collections
  final Map<String, FirebaseFirestoreCollection> collections = {};

  ValueExceptionPair<CollectionReference<Map<String, dynamic>>, dynamic> getCollectionByPath(String path) {
    try {
      final returnValue = firebaseFirestore.collection(path);
      return ValueExceptionPair(returnValue);
    } catch (e) {
      //Different types of exceptions are thrown here, not just FirebaseException
      return ValueExceptionPair(null, exception: e);
    }
  }
  //endregion

  //region Buckets
  final Map<String, FirebaseStorageBucket> buckets = {};
  //endregion

  //region Emulator
  //Emulator selection/settings/modifications must be called immediately, prior to accessing FirebaseFirestore or FirebaseAuth methods.
  //To comply, only allow settings to be applied once, after instantiation
  bool _hasAppliedEmulatorSettings = false;

  FirebaseValueExceptionPair<bool> _applyEmulatorSettings() {
    final returnValue = FirebaseValueExceptionPair(false);

    if (super.useEmulator && !_hasAppliedEmulatorSettings) {
      try {
        firebaseFirestore.useFirestoreEmulator(emulatorHostnameOrIpAddress, emulatorPort, sslEnabled: sslEnabled);
        returnValue.value = true;
      } on FirebaseException catch (e) {
        returnValue.exception = e;
      }
    }

    _hasAppliedEmulatorSettings = true;
    return returnValue;
  }
  //endregion

  //region Settings
  int? cacheSizeBytes;
  bool ignoreUndefinedProperties = true;
  bool sslEnabled = false;

  //Emulator selection/settings/modifications must be called immediately, prior to accessing FirebaseFirestore or FirebaseAuth methods.
  //To comply, only allow settings to be applied once, after instantiation
  bool _hasAppliedSettings = false;

  ValueExceptionPair<bool, dynamic> _applySettings() {
    final returnValue = ValueExceptionPair(false);

    if (!_hasAppliedSettings) {
      Settings settings = Settings(
        persistenceEnabled: persistenceEnabled,
        host: emulatorHostnameOrIpAddress,
        sslEnabled: sslEnabled,
        cacheSizeBytes: cacheSizeBytes
        //intentionally omitting ignoreUndefinedProperties as it only applies to web
      );

      if(kIsWeb) {
        settings = Settings(
          //intentionally omitting persistenceEnabled as it has no effect on web. Instead, call setPersistenceForWeb
          host: emulatorHostnameOrIpAddress,
          sslEnabled: sslEnabled,
          cacheSizeBytes: cacheSizeBytes,
          ignoreUndefinedProperties: ignoreUndefinedProperties
        );
      }

      try {
        firebaseFirestore.settings = settings;
        returnValue.value = true;
      } catch (e) {
        //Different types of exceptions are thrown here, not just FirebaseException
        returnValue.exception = e;
      }

      _hasAppliedSettings = true;
    }

    return returnValue;
  }
  //endregion

  //region Persistence
  bool persistenceEnabled = true;

  /// Enable persistence of Firestore data for web-only. Use [Settings.persistenceEnabled] for non-web platforms.
  /// If `enablePersistence()` is not called, it defaults to Memory cache.
  /// If `enablePersistence(const PersistenceSettings(synchronizeTabs: false))` is called, it persists data for a single browser tab.
  /// If `enablePersistence(const PersistenceSettings(synchronizeTabs: true))` is called, it persists data across multiple browser tabs.
  Future<FirebaseValueExceptionPair<bool>> setPersistenceForWeb({PersistenceSettings? persistenceSettings}) async {
    if (kIsWeb && persistenceEnabled) {//This doesn't check canModifySettings as the following settings can apparently be set as desired
      try {
        await firebaseFirestore.enablePersistence(persistenceSettings ?? const PersistenceSettings(synchronizeTabs: false));
        return FirebaseValueExceptionPair(true);
      } on FirebaseException catch(e) {
        return FirebaseValueExceptionPair(false, exception: e);
      }
    }
    return FirebaseValueExceptionPair(false);
  }

  //https://stackoverflow.com/questions/63930954/how-to-properly-call-firebasefirestore-instance-clearpersistence-in-flutter/64380036#64380036
  Future<FirebaseValueExceptionPair<bool>> clearPersistedData() async {
    try {
      //await FirebaseFirestore.instance.terminate();//<-I'm hoping this isn't required as stated in the SO post, because it'll mean restarting Firestore :(
      await firebaseFirestore.clearPersistence();
      return FirebaseValueExceptionPair(true);
    } on FirebaseException catch (e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }
  //endregion

  //region Networking
  Future<FirebaseValueExceptionPair<bool>> enableNetworking() async {
    try {
      await firebaseFirestore.enableNetwork();
      return FirebaseValueExceptionPair(true);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }

  Future<FirebaseValueExceptionPair> disableNetworking() async {
    try {
      await firebaseFirestore.disableNetwork();
      return FirebaseValueExceptionPair(true);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }
  //endregion

  //region Writing to Firebase
  ValueExceptionPair<WriteBatch, dynamic> getWriteBatch() {
    try {
      final returnValue = firebaseFirestore.batch();
      return ValueExceptionPair(returnValue);
    } catch (e) {
      return ValueExceptionPair(null, exception: e);
    }
  }

  Future<FirebaseValueExceptionPair<bool>> waitForPendingWrites() async {
    try {
      await firebaseFirestore.waitForPendingWrites();
      return FirebaseValueExceptionPair(true);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }
  //endregion
}