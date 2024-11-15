// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:larosa_block/Utils/colors.dart';
// import 'package:larosa_block/Utils/text_theme.dart';

// class LarosaAppTheme {
//   LarosaAppTheme._();

//   static final ThemeData lightTheme = ThemeData(
//     snackBarTheme: const SnackBarThemeData(
//       backgroundColor: LarosaColors.primary,
//       contentTextStyle: TextStyle(color: LarosaColors.light),
//     ),
//     useMaterial3: true,
//     fontFamily: GoogleFonts.roboto().fontFamily,
//     filledButtonTheme: FilledButtonThemeData(
//       style: FilledButton.styleFrom(
//         backgroundColor: LarosaColors.primary,
//         shape: ContinuousRectangleBorder(
//           borderRadius: BorderRadius.circular(0),
//         ),
//       ),
//     ),
//     colorScheme: ColorScheme.fromSeed(
//       secondary: Colors.black,
//       seedColor: LarosaColors.primary,
//       brightness: Brightness.light,
//       background: Colors.white,
//       error: Colors.red,
//     ),
//     disabledColor: LarosaColors.grey,
//     brightness: Brightness.light,
//     scaffoldBackgroundColor: Colors.white,
//     primaryColor: LarosaColors.primary,
//     appBarTheme: const AppBarTheme(
//       color: Colors.white,
//       iconTheme: IconThemeData(color: Colors.black),
//       titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
//       systemOverlayStyle: SystemUiOverlayStyle(
//         statusBarColor: Colors.white,
//         statusBarIconBrightness: Brightness.dark,
//         systemNavigationBarColor: Colors.white,
//         systemNavigationBarIconBrightness: Brightness.dark,
//       ),
//     ),
//     iconTheme: const IconThemeData(color: Colors.black),
//     textTheme: LarosaTextTheme.lightTextTheme.apply(
//       bodyColor: Colors.black,
//       displayColor: Colors.black,
//     ),
//   );

//   static final ThemeData darkTheme = ThemeData(
//     snackBarTheme: const SnackBarThemeData(
//       backgroundColor: LarosaColors.primary,
//       contentTextStyle: TextStyle(color: LarosaColors.light),
//     ),
//     useMaterial3: true,
//     fontFamily: GoogleFonts.roboto().fontFamily,
//     filledButtonTheme: FilledButtonThemeData(
//       style: FilledButton.styleFrom(
//         backgroundColor: LarosaColors.primary,
//         shape: ContinuousRectangleBorder(
//           borderRadius: BorderRadius.circular(0),
//         ),
//       ),
//     ),
//     colorScheme: ColorScheme.fromSeed(
//       secondary: Colors.white,
//       seedColor: LarosaColors.primary,
//       brightness: Brightness.dark,
//       background: Colors.black,
//       error: Colors.red,
//     ),
//     disabledColor: LarosaColors.grey,
//     brightness: Brightness.dark,
//     scaffoldBackgroundColor: Colors.black,
//     primaryColor: LarosaColors.primary,
//     appBarTheme: const AppBarTheme(
//       color: Colors.black,
//       iconTheme: IconThemeData(color: Colors.white),
//       titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
//       systemOverlayStyle: SystemUiOverlayStyle(
//         statusBarColor: Colors.black,
//         statusBarIconBrightness: Brightness.light,
//         systemNavigationBarColor: Colors.black,
//         systemNavigationBarIconBrightness: Brightness.light,
//       ),
//     ),
//     iconTheme: const IconThemeData(color: Colors.white),
//     textTheme: LarosaTextTheme.darkTextTheme.apply(
//       bodyColor: Colors.white,
//       displayColor: Colors.white,
//     ),
//   );

//   // Call this method to set the system UI overlay style based on the theme
//   static void setSystemUIOverlayStyle(ThemeMode themeMode) {
//     SystemUiOverlayStyle overlayStyle = themeMode == ThemeMode.dark
//         ? const SystemUiOverlayStyle(
//             statusBarColor: Colors.black,
//             statusBarIconBrightness: Brightness.light,
//             systemNavigationBarColor: Colors.black,
//             systemNavigationBarIconBrightness: Brightness.light,
//           )
//         : const SystemUiOverlayStyle(
//             statusBarColor: Colors.white,
//             statusBarIconBrightness: Brightness.dark,
//             systemNavigationBarColor: Colors.white,
//             systemNavigationBarIconBrightness: Brightness.dark,
//           );
//     SystemChrome.setSystemUIOverlayStyle(overlayStyle);
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/text_theme.dart';

class LarosaAppTheme {
  LarosaAppTheme._();

  static final ThemeData lightTheme = ThemeData(
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LarosaColors.primary,
      contentTextStyle: TextStyle(color: LarosaColors.light),
    ),
    useMaterial3: true,
    fontFamily: GoogleFonts.roboto().fontFamily,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LarosaColors.primary,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      secondary: Colors.black,
      seedColor: LarosaColors.primary,
      brightness: Brightness.light,
      background: Colors.white,
      error: Colors.red,
    ),
    disabledColor: LarosaColors.grey,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: LarosaColors.primary,
    appBarTheme: const AppBarTheme(
      color: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    textTheme: LarosaTextTheme.lightTextTheme.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: Colors.black54), // Hint text color for light theme
      prefixIconColor: Colors.black,
      suffixIconColor: Colors.black,
      filled: true,
      fillColor: Colors.grey.withOpacity(.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: LarosaColors.primary),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LarosaColors.primary,
      contentTextStyle: TextStyle(color: LarosaColors.light),
    ),
    useMaterial3: true,
    fontFamily: GoogleFonts.roboto().fontFamily,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LarosaColors.primary,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      secondary: Colors.white,
      seedColor: LarosaColors.primary,
      brightness: Brightness.dark,
      background: Colors.black,
      error: Colors.red,
    ),
    disabledColor: LarosaColors.grey,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: LarosaColors.primary,
    appBarTheme: const AppBarTheme(
      color: Colors.black,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: LarosaTextTheme.darkTextTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: Colors.white70), // Hint text color for dark theme
      prefixIconColor: Colors.white,
      suffixIconColor: Colors.white,
      filled: true,
      fillColor: Colors.grey.withOpacity(.2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: LarosaColors.primary),
      ),
    ),
  );

  // Method to set the system UI overlay style
  static void setSystemUIOverlayStyle(ThemeMode themeMode) {
    SystemUiOverlayStyle overlayStyle = themeMode == ThemeMode.dark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          );
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }
}
