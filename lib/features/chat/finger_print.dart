import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

class FingerprintLoginScreen extends StatefulWidget {
  const FingerprintLoginScreen({super.key});

  @override
  State<FingerprintLoginScreen> createState() => _FingerprintLoginScreenState();
}

class _FingerprintLoginScreenState extends State<FingerprintLoginScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _isAuthenticating = false;
  bool _canCheckBiometrics = false;
  String _statusMessage = 'Tap the fingerprint icon to login';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkBiometricSupport();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck && isSupported;
        if (!_canCheckBiometrics) {
          _statusMessage = 'Biometric authentication not available';
        }
      });

      // Auto-trigger auth as soon as the screen opens
      if (_canCheckBiometrics) {
        _authenticate();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking biometrics: $e';
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Scanning...';
    });

    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',

        options: const AuthenticationOptions(
          biometricOnly: true, // forces fingerprint/Face ID, no PIN fallback
          stickyAuth: true, // keeps auth alive across app backgrounding
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _statusMessage = 'Authenticated successfully!';
        });
        _goToNextScreen();
      } else {
        setState(() {
          _statusMessage = 'Authentication failed. Try again.';
        });
      }
    } on PlatformException catch (e) {
      String message;
      if (e.code == auth_error.notAvailable) {
        message = 'Biometric authentication not available';
      } else if (e.code == auth_error.notEnrolled) {
        message = 'No fingerprints enrolled on this device';
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        message = 'Too many attempts. Try again later';
      } else {
        message = 'Error: ${e.message}';
      }
      setState(() {
        _statusMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _goToNextScreen() {
    // Replace with your actual next screen / route
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Authenticate to continue',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 60),

                // Fingerprint button with pulse + ripple effect
                GestureDetector(
                  onTap: _canCheckBiometrics ? _authenticate : null,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E293B),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF38BDF8,
                                ).withOpacity(_isAuthenticating ? 0.4 : 0.15),
                                blurRadius: 30,
                                spreadRadius: _isAuthenticating ? 8 : 2,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF38BDF8),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            size: 70,
                            color: _isAuthenticating
                                ? const Color(0xFF38BDF8)
                                : Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                if (_isAuthenticating)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF38BDF8),
                    ),
                  ),

                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _statusMessage.contains('failed') ||
                            _statusMessage.contains('Error') ||
                            _statusMessage.contains('not available')
                        ? Colors.redAccent
                        : Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // Retry button
                if (!_isAuthenticating && _canCheckBiometrics)
                  TextButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(color: Color(0xFF38BDF8)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dummy next screen — replace with your real one
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Logged in successfully!')),
    );
  }
}
