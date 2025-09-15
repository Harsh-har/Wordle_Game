import 'package:flutter/material.dart';
import 'Home_Screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 50),
            Column(
              children: [
                Image.asset(
                  'assets/images/splashicon.png',
                  height: 130,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Wordle Game',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: (Color(0xFF3E8642)
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    'Lets play a game ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(25.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff5f9658)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
