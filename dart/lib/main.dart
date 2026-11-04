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
        apiKey: "AIzaSyCoxrOMad3zry3hlqS9ZGAvXLBNYJ9ZHQU",
        appId: "1:490940411719:web:88a3fa40939a2991dfa662",
        messagingSenderId: "490940411719",
        projectId: "cuwo-74f73",
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
