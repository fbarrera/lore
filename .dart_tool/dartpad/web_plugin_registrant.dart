// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:camera_web/camera_web.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:cloud_functions_web/cloud_functions_web.dart';
import 'package:file_selector_web/file_selector_web.dart';
import 'package:firebase_app_check_web/firebase_app_check_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_tts/flutter_tts_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:record_web/record_web.dart';
import 'package:speech_to_text/speech_to_text_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  CameraPlugin.registerWith(registrar);
  FirebaseFirestoreWeb.registerWith(registrar);
  FirebaseFunctionsWeb.registerWith(registrar);
  FileSelectorWeb.registerWith(registrar);
  FirebaseAppCheckWeb.registerWith(registrar);
  FirebaseAuthWeb.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  FlutterTtsPlugin.registerWith(registrar);
  ImagePickerPlugin.registerWith(registrar);
  RecordPluginWeb.registerWith(registrar);
  SpeechToTextPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
