import 'package:flutter/material.dart';
import 'felulet/bejel.dart';
import 'felulet/menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF00C853);
    return MaterialApp(
      title: 'Proiect Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const BejelentkezesPage(),
        '/menu': (_) => const MenuScreen(),
      },
    );
  }
}
