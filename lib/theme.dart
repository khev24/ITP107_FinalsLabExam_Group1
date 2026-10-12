import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------- Brand palette (forest green, sage, gold, bronze) ----------
const Color kPrimary = Color(0xFF0C3B2E); // deep forest green - main
const Color kPrimaryDark = Color(0xFF072A20); // darker green for pressed/text
const Color kSage = Color(0xFF6D9773); // sage green - secondary
const Color kSageLight = Color(0xFFE2ECE4); // soft sage tint (chips, avatars)
const Color kSageSoft = Color(0xFFF1F6F2); // very light sage (note boxes)
const Color kGold = Color(0xFFFFBA00); // golden yellow - highlights
const Color kBronze = Color(0xFFB46617); // bronze - small labels, accents

const Color kBg = Color(0xFFF3F8F4); // app background (pale mint)
const Color kSurface = Colors.white; // cards, sheets, dialogs
const Color kInk = Color(0xFF0F2A22); // main text
const Color kBodyText = Color(0xFF34473F); // long-form reading text
const Color kMuted = Color(0xFF6B7C74); // secondary text
const Color kBorder = Color(0xFFDFE9E2); // hairline borders
const Color kDanger = Color(0xFFC62828);
const Color kDangerLight = Color(0xFFFDE4E4);
const Color kSuccess = Color(0xFF2E6B3F);
const Color kSuccessLight = Color(0xFFE2F1E5);
const Color kShadow = Color(0x0F0C3B2E); // very soft green-tinted shadow

/// Shared card look: white surface, hairline border, soft shadow.
BoxDecoration cardDecoration({double radius = 20, Color color = kSurface}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kBorder),
    boxShadow: const [
      BoxShadow(color: kShadow, blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
    primary: kPrimary,
    onPrimary: Colors.white,
    secondary: kSage,
    onSecondary: Colors.white,
    tertiary: kGold,
    onTertiary: kPrimary,
    surface: kSurface,
    onSurface: kInk,
    error: kDanger,
    outline: kBorder,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  // Poppins everywhere
  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
      .apply(bodyColor: kInk, displayColor: kInk)
      .copyWith(
        headlineSmall: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: kInk,
            height: 1.25,
            letterSpacing: -0.4),
        titleLarge: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700, color: kInk),
        titleMedium: GoogleFonts.poppins(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: kInk,
            height: 1.35),
        bodyLarge:
            GoogleFonts.poppins(fontSize: 16.5, height: 1.85, color: kBodyText),
        bodyMedium:
            GoogleFonts.poppins(fontSize: 14, height: 1.5, color: kMuted),
      );

  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w700, color: kInk),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kPrimary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: kPrimary,
      selectionColor: kSage.withAlpha(90),
      selectionHandleColor: kSage,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      hintStyle: const TextStyle(color: kMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kSage, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDanger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kSageLight,
        disabledForegroundColor: kMuted,
        elevation: 0,
        textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, letterSpacing: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kInk,
        side: const BorderSide(color: kBorder, width: 1.2),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      highlightElevation: 4,
      extendedTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
