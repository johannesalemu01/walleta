import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../core/colors.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppShellState {
  // placeholder
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    final security = context.read<SecurityProvider>();
    if (security.hasBiometric && security.appLockEnabled) {
      await security.unlockWithBiometric();
    }
  }

  void _onKeyPress(String val) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += val;
      _error = null;
    });

    if (_pin.length == 4) {
      _verify();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    final security = context.read<SecurityProvider>();
    final ok = await security.unlockWithPin(_pin);
    if (!ok) {
      setState(() {
        _pin = '';
        _error = 'Incorrect PIN. Please try again.';
      });
    }
  }

  Widget _buildDot(int index) {
    final filled = index < _pin.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.accent : Colors.grey.withOpacity(0.3),
        border: Border.all(
          color: filled ? AppColors.accent : Colors.grey.withOpacity(0.5),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onPressed, Widget? child}) {
    return InkWell(
      onTap: onPressed ?? () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 75,
        height: 75,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.04),
        ),
        child: child ??
            Text(
              label,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Header
            Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'App Locked',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your 4-digit PIN to continue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildDot(index)),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const Spacer(),

            // Dialpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKey('1'),
                      _buildKey('2'),
                      _buildKey('3'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKey('4'),
                      _buildKey('5'),
                      _buildKey('6'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKey('7'),
                      _buildKey('8'),
                      _buildKey('9'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Biometric
                      security.hasBiometric
                          ? _buildKey(
                              'bio',
                              onPressed: _checkBiometrics,
                              child: Icon(
                                Icons.fingerprint,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            )
                          : const SizedBox(width: 75, height: 75),
                      _buildKey('0'),
                      _buildKey(
                        'del',
                        onPressed: _onDelete,
                        child: const Icon(
                          Icons.backspace_outlined,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
