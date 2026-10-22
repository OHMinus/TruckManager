import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'pages/calendar_page.dart';
import 'pages/detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Using placeholders for FirebaseOptions so it compiles without a valid firebase_options.dart.
  // The user should replace these with actual credentials to use it online.
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "placeholder_api_key",
        appId: "placeholder_app_id",
        messagingSenderId: "placeholder_sender_id",
        projectId: "placeholder_project_id",
      ),
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const CalendarPage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'order/:id',
          builder: (BuildContext context, GoRouterState state) {
            return DetailPage(id: state.pathParameters['id']!);
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Order Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
