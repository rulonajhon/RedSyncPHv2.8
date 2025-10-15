import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hemophilia_manager/routes/routes.dart';
import 'package:hemophilia_manager/screens/registration/authentication_landing_screen.dart';
import 'package:hemophilia_manager/screens/onboarding/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hemophilia_manager/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hemophilia_manager/screens/main_screen/patient_screens/main_screen_hud.dart';
import 'package:hemophilia_manager/screens/main_screen/healthcare_provider_screen/healthcare_main_screen.dart';
import 'package:hemophilia_manager/screens/admin/admin_dashboard.dart';
import 'package:hemophilia_manager/services/openai_service.dart';
import 'package:hemophilia_manager/services/notification_service.dart';
import 'package:hemophilia_manager/services/firestore.dart';
import 'package:hemophilia_manager/services/offline_service.dart';
import 'package:hemophilia_manager/auth/auth.dart';
import 'package:hemophilia_manager/services/auth_state_manager.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize OpenAI service
  try {
    await OpenAIService.initialize();
  } catch (e) {
    print('Warning: Failed to initialize OpenAI service: $e');
  }

  // Initialize Notification service and cancel all old notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initNotifications();
    print('Notification service initialized');
  } catch (e) {
    print('Warning: Failed to initialize Notification service: $e');
    // App can still function without notifications
    // Don't rethrow to prevent app startup crash
  }

  // Clean up expired unverified medical accounts
  try {
    final FirestoreService firestoreService = FirestoreService();
    await firestoreService.cleanupExpiredUnverifiedAccounts();
    print('Expired account cleanup completed');
  } catch (e) {
    print('Warning: Failed to cleanup expired accounts: $e');
  }

  // Initialize Offline service for local storage and sync
  try {
    final OfflineService offlineService = OfflineService();
    await offlineService.initialize();
    print('Offline service initialized successfully');
  } catch (e) {
    print('Warning: Failed to initialize Offline service: $e');
  }

  // Initialize authentication state manager
  try {
    final authStateManager = AuthStateManager();
    authStateManager.initialize();
    print('✅ Auth state manager initialized');
  } catch (e) {
    print('Warning: Failed to initialize auth state manager: $e');
  }

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Notification handling is managed by NotificationService
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'RedSyncPH',
          theme: ThemeData(
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.redAccent,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.grey[50],
            dividerColor: Colors.grey[300],
          ),
          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          home: const AppInitializer(),
          routes: AppRoutes.routes,
        );
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AuthService _authService = AuthService(); // Added AuthService instance

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check onboarding status
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (!mounted) return;

      if (!onboardingComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
        return;
      }

      // Validate authentication state consistency
      final isAuthValid = await _authService.validateAuthState();

      if (!isAuthValid) {
        print('🔄 Auth state invalid, redirecting to login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthenticationLandingScreen(),
          ),
        );
        return;
      }

      // Get login status and user role from secure storage
      final isLoggedIn = await _secureStorage.read(key: 'isLoggedIn');
      String? userRole = await _secureStorage.read(key: 'userRole');

      // If user role is missing but we have a valid Firebase user, try to retrieve it
      if (userRole == null || userRole.isEmpty) {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          print('🔄 User role missing, attempting to retrieve from Firestore');
          try {
            final firestoreService = FirestoreService();
            userRole = await firestoreService.getUserRole(currentUser.uid);

            if (userRole != null && userRole.isNotEmpty) {
              // Save the retrieved role to secure storage
              await _secureStorage.write(key: 'userRole', value: userRole);
              print('✅ User role retrieved and saved: $userRole');
            }
          } catch (e) {
            print('❌ Failed to retrieve user role from Firestore: $e');
          }
        }
      }

      if (!mounted) return;

      if (isLoggedIn == 'true' && userRole != null && userRole.isNotEmpty) {
        // User is logged in, navigate to appropriate screen
        Widget targetScreen;
        switch (userRole) {
          case 'patient':
          case 'caregiver':
            targetScreen = const MainScreenDisplay();
            break;
          case 'medical':
          case 'doctor':
          case 'healthcare_provider':
            targetScreen = const HealthcareMainScreen();
            break;
          case 'admin':
            targetScreen = const AdminDashboard();
            break;
          default:
            print('⚠️ Unknown user role: $userRole, redirecting to login');
            targetScreen = const AuthenticationLandingScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      } else {
        // User is not logged in or role is missing, go to login
        print('🔄 User not logged in or role missing, redirecting to login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthenticationLandingScreen(),
          ),
        );
      }
    } catch (e) {
      // If any error occurs, default to login
      print('❌ Error during app initialization: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthenticationLandingScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'RedSyncPH',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}
