import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/crop_suggestion_screen.dart';
import 'screens/fertilizer_tips_screen.dart';
import 'screens/market_price_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/marketplace_screen.dart';
import 'services/auth_service.dart';
import 'services/crop_recommendation_service.dart';
import 'screens/soil_based_recommendation_screen.dart';
import 'screens/disease_detection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase AppCheck
  await FirebaseAppCheck.instance.activate(
    // Use provider appropriate for each platform
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  
  // Initialize services
  final cropRecommendationService = CropRecommendationService();
  await cropRecommendationService.initialize();
  
  runApp(const AgriAIApp());
}
class AgriAIApp extends StatelessWidget {
  const AgriAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'AgriAI - Smart Farming Assistant',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, child) {
            return authService.isSignedIn 
                ? const DashboardScreen()
                : const LoginScreen();
          },
        ),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/crop-suggestions': (context) => const CropSuggestionScreen(),
          '/fertilizer-tips': (context) => const FertilizerTipsScreen(),
          '/market-price': (context) => const MarketPriceScreen(),
          '/weather': (context) => const WeatherScreen(),
          '/marketplace': (context) => const MarketplaceScreen(),
          '/soil-recommendation': (context) => const SoilBasedRecommendationScreen(),
          '/disease-detection': (context) => const DiseaseDetectionScreen(),
        },
      ),
    );
  }
}