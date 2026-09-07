import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Rediriger vers Login après 2.5 secondes
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5D4037), // Marron foncé
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 3D animé (icône café)
            Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.brown[800]!,
                        Colors.brown[600]!,
                        Colors.amber[700]!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.coffee,
                    color: Colors.white,
                    size: 80,
                  ),
                )
                .animate()
                // Rotation 3D (effet de perspective)
                .rotate(
                  duration: 3.seconds,
                  curve: Curves.easeInOut,
                  begin: 0,
                  end: 0.2, // Petite rotation pour effet 3D
                )
                .then()
                .scale(
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                )
                .then()
                // Effet de lumière (shimmer)
                .shimmer(
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                  color: Colors.white.withOpacity(0.3),
                  delay: 0.5.seconds,
                ),

            const SizedBox(height: 32),

            // Nom de l'application
            const Text(
                  'CaféFlow',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 1.seconds, delay: 0.3.seconds)
                .slideY(begin: 0.3, end: 0, duration: 0.8.seconds),

            const SizedBox(height: 8),

            // Sous-titre
            const Text(
                  'Votre café, votre moment',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                )
                .animate()
                .fadeIn(duration: 1.seconds, delay: 0.8.seconds)
                .slideY(begin: 0.3, end: 0, duration: 0.8.seconds),

            const SizedBox(height: 48),

            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ).animate().fadeIn(duration: 0.8.seconds, delay: 1.2.seconds),
          ],
        ),
      ),
    );
  }
}
