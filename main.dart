import 'package:flutter/material.dart';
import 'auth.dart';
import 'db.dart';
import 'screens.dart';
import 'util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Auth.seed();
  await Db.I.db;
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Doctor Appointment Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
          scaffoldBackgroundColor: const Color(0xFFF4F8FD),
          appBarTheme: const AppBarTheme(backgroundColor: kBlue, foregroundColor: Colors.white),
          cardTheme: const CardThemeData(color: Colors.white, elevation: 1, margin: EdgeInsets.symmetric(vertical: 4)),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        ),
        home: const LoginScreen(),
      );
}
