import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs once before every test in this directory.
///
/// Widget tests ship no fonts, so text falls back to a stand-in whose glyphs
/// are far wider than the real thing. Layouts that fit comfortably in a browser
/// then overflow by hundreds of pixels under test, which buries a genuine
/// layout bug in a pile of false ones.
///
/// The app renders in Roboto, so registering the real Roboto here makes a
/// measurement in a test mean what it means on screen - and an overflow error
/// something worth reading. The weights are the four the UI actually uses;
/// Flutter interpolates the rest.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const weights = [
    'roboto-regular.ttf', // w400
    'roboto-medium.ttf', // w500
    'roboto-bold.ttf', // w700
    'roboto-black.ttf', // w900
  ];

  final loader = FontLoader('Roboto');
  for (final file in weights) {
    loader.addFont(
      File('test/fonts/$file').readAsBytes().then((bytes) => bytes.buffer.asByteData()),
    );
  }
  await loader.load();

  return testMain();
}
