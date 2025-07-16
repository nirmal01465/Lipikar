// launch_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/finances_colors.dart';
import '../widgets/horizontal_long_arrow_widget.dart';
import '../widgets/titled_bar_widget.dart';
import 'home_page.dart';
import 'login_page.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({Key? key}) : super(key: key);

  @override
  _LaunchPageState createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Delay for splash effect
    Timer(const Duration(seconds: 3), _checkAuthentication);
  }

  Future<void> _checkAuthentication() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            const SizedBox(height: 120),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Best',
                    style: TextStyle(
                      fontSize: 45,
                      color: DocAppColors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Translator',
                    style: TextStyle(
                      fontSize: 45,
                      color: DocAppColors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Point',
                    style: TextStyle(
                      fontSize: 45,
                      color: DocAppColors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'App',
                    style: TextStyle(
                      fontSize: 45,
                      color: DocAppColors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            const AnimatedTiltedBarWidget(),
            const SizedBox(height: 30),
            const AnimatedHorizontalArrowWidget(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}