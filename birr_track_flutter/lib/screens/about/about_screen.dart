import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.text),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 24), // Spacer to balance back button
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Logo Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/icon.png',
                              width: 80,
                              height: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.primary,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.receipt_long, size: 40, color: Colors.white),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Birr Track',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Version 1.0.0',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi there! I am Henok, a software engineer.',
                            style: TextStyle(fontSize: 15, height: 1.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'I built this app because I couldn\'t find the perfect tool for my needs to manage expenses and to track loans and debts with my friends.',
                            style: TextStyle(fontSize: 15, height: 1.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Feel free to reach out for any bug fixes and feature requests.',
                            style: TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact Card
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse('https://henokenyew.me')),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.language, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Henok Enyew',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'henokenyew.me',
                                    style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Check out my portfolio',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Footer
                    const Text(
                      '© 2026 Ethiopia. All rights reserved.',
                      style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
