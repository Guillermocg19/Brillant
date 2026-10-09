import 'package:flutter/material.dart';

/// Tema único de la app. Centralizarlo aquí evita repetir estilos de
/// botón/chip/appbar en cada pantalla por separado.
final ThemeData temaBrillant = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF4F5F9),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black87,
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  ),
  chipTheme: ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    selectedColor: Colors.indigo.shade400,
    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    secondaryLabelStyle:
        const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.bold),
  ),
);