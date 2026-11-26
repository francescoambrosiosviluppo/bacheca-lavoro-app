import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'screens/board_screen.dart';

/// Notifica alla bacheca quando torna visibile, così si aggiorna da sola.
final routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(prefs);
  state.validateSession(); // non blocca l'avvio
  runApp(ChangeNotifierProvider.value(value: state, child: const BachecaApp()));
}

class BachecaApp extends StatelessWidget {
  const BachecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F5FAD);
    return MaterialApp(
      title: 'Bacheca Lavoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      navigatorObservers: [routeObserver],
      home: const BoardScreen(),
    );
  }
}
