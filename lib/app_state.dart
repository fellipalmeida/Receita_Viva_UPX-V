import 'package:flutter/material.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final tabNotifier = ValueNotifier<int>(0);
final searchNotifier = ValueNotifier<String>('');
