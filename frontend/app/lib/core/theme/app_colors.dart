import 'package:flutter/material.dart';

// Única cor de marca. Os demais acentos são derivados dela.
const primary = Color(0xff9f4d4d);
const bgStart = Color(0xfffefbf3);
const bgEnd = Color(0xfffbebdc);
const foreground = Color(0xff542a30);
final border = Color.lerp(primary, bgStart, .72)!;
