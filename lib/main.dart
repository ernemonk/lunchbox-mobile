import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/subscription_service.dart';
import 'views/login_page.dart';
import 'views/signup_page.dart';
import 'views/home_page.dart';
// Temporarily commented until l10n generation works
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Lunchbox());
}

/// Main application widget.
/// 
/// Configures the MaterialApp with:
/// - Global theme from [AppTheme]
/// - Firebase authentication wrapper
/// - App routes
class Lunchbox extends StatelessWidget {
  const Lunchbox({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lunchbox',
      
      // Localization delegates - temporarily disabled until generation works
      // localizationsDelegates: const [
      //   AppLocalizations.delegate,
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en'), // English
      //   Locale('es'), // Spanish
      //   Locale('fr'), // French
      // ],
      
      // Apply global theme
      theme: AppTheme.lightTheme,
      
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const MyHomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}

/// Authentication state wrapper.
/// 
/// Listens to Firebase auth state changes and redirects to:
/// - [MyHomePage] if user is authenticated
/// - [LoginPage] if user is not authenticated
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkExpiredSubscriptions();
  }

  Future<void> _checkExpiredSubscriptions() async {
    // Check and update expired subscriptions when app starts
    try {
      await SubscriptionService.checkAndUpdateExpiredSubscriptions();
    } catch (e) {
      print('[SUBSCRIPTION] Error checking expired subscriptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Check subscriptions when auth state changes
        if (snapshot.hasData) {
          _checkExpiredSubscriptions();
        }
        
        return snapshot.hasData ? const MyHomePage() : const LoginPage();
      },
    );
  }
}
