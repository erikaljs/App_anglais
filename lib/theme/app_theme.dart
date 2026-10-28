import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Le thème visuel de l'application : couleurs, police, forme des
/// boutons et des cartes. Utilisé une seule fois, dans main.dart.
class AppTheme {
  AppTheme._();

  static ThemeData get clair {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bleuPrincipal,
        primary: AppColors.bleuPrincipal,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.fond,
    );

    // On applique la police "Plus Jakarta Sans" à tout le texte de l'appli.
    final texte = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: texte,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.fond,
        foregroundColor: AppColors.bleuFonce,
        elevation: 0,
        titleTextStyle: texte.titleLarge?.copyWith(
          color: AppColors.bleuFonce,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.carteBordure),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bleuPrincipal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.bleuPrincipal.withValues(alpha: 0.12),
      ),
    );
  }
}
