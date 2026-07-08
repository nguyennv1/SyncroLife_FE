import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/main_navigation.dart';
import 'theme/custom_icons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'SyncroLife',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto', // Default fallback font, you can change to match Android more closely
        ),
        home: Consumer<AppState>(
          builder: (context, appState, child) {
            if (!appState.isInitialized) {
              return const Scaffold(
                backgroundColor: Color(0xFF0B0F19),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LightningBoltIcon(size: 60, tint: Color(0xFF10B981)),
                      SizedBox(height: 24),
                      CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (appState.isLoggedIn) {
              return appState.isAdmin ? const AdminDashboardScreen() : MainNavigation();
            }
            return LoginScreen();
          },
        ),
      ),
    );
  }
}
