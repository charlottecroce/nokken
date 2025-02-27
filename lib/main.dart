//
//  main.dart
//  App entry point
//
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nokken/src/app.dart';

/// Application entry point
void main() {
  // Ensure Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Use FFI implementation for desktop platforms
  // Mobile platforms use the standard implementation
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Launch the app with Riverpod as the state management provider
  runApp(
    const ProviderScope(
      child: NokkenApp(),
    ),
  );
}
