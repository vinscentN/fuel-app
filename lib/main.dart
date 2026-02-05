import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/fuel_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/buffalo_provider.dart';
import 'routes/app_routes.dart';
import 'utils/colors.dart';
import 'utils/buffalo_colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/pos_test_screen.dart';
import 'screens/home/landing_menu_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/buffalo/buffalo_main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();

  runApp(FuelStationApp(authProvider: authProvider));
}

class FuelStationApp extends StatelessWidget {
  final AuthProvider authProvider;

  const FuelStationApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => FuelProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => BuffaloProvider()),
      ],
      child: MaterialApp(
        title: 'Buffalo Brewing Company',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: BuffaloColors.primarySwatch,
          primaryColor: BuffaloColors.primary,
          scaffoldBackgroundColor: BuffaloColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: BuffaloColors.primary,
            primary: BuffaloColors.primary,
            secondary: BuffaloColors.secondary,
            tertiary: BuffaloColors.tertiary,
            surface: BuffaloColors.surface,
            error: BuffaloColors.error,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: BuffaloColors.primary,
            foregroundColor: Colors.white,
            elevation: 1,
          ),
          textTheme: GoogleFonts.manropeTextTheme(),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: BuffaloColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BuffaloColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BuffaloColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BuffaloColors.secondary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
        ),
        // Buffalo Brewing Company main menu is the entry point
        home: const BuffaloMainMenuScreen(),
      ),
    );
  }
}
