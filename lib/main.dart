//
//  /main.dart
//
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nokken/src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    // use ffi for desktop platforms
    // no mobile devices have been tested yet
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const ProviderScope(
      child: NokkenApp(),
    ),
  );
}
