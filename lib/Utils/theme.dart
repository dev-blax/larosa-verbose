import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/text_theme.dart';

class LarosaAppTheme {
  LarosaAppTheme._();

  static ThemeData lightTheme = ThemeData(
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LarosaColors.primary,
      contentTextStyle: TextStyle(color: LarosaColors.light),
    ),
    useMaterial3: true,
    fontFamily: GoogleFonts.roboto().fontFamily,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LarosaColors.primary,
        shape: const ContinuousRectangleBorder(),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      // secondary: LarosaColors.dark,
      secondary: Colors.black,
      seedColor: LarosaColors.primary,
      brightness: Brightness.light,
      //secondaryContainer: LarosaPalette.secondaryContainerLight,
      //tertiaryContainer: LarosaPalette.onPrimaryColorLight,
      background: Colors.white,
      error: Colors.purple,
    ),
    disabledColor: LarosaColors.grey,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: LarosaColors.primary,
    textTheme: LarosaTextTheme.lightTextTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.roboto().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      //tertiaryContainer: LarosaPalette.onPrimaryColorDark,
      //secondaryContainer: LarosaPalette.secondaryContainerDark,
      secondary: Colors.white,
      seedColor: LarosaColors.primary,
      brightness: Brightness.dark,
      background: Colors.black,
      // background: LarosaColors.dark,
      error: Colors.purple,
    ),
    disabledColor: LarosaColors.grey,
    brightness: Brightness.dark,
    // scaffoldBackgroundColor: LarosaColors.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: LarosaColors.primary,
    textTheme: LarosaTextTheme.darkTextTheme,
  );
}
