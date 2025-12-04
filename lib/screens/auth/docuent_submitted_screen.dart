import 'package:fixify_admin/screens/dashboard/dashboard_screen.dart';
import 'package:fixify_admin/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class DocumentsSubmittedScreen extends StatelessWidget {
  const DocumentsSubmittedScreen({super.key});

  static const Color _green = Color(0xFF2F6F3E);
  static const Color _lightGreen = Color(0xFFE6F6E7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: _lightGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Documents Submitted',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(height: 24, width: double.infinity, color: _lightGreen),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green.withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: _green,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Documents Successfully\nSubmitted!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your documents have been received. Our team is reviewing them, and you will receive an update by email once the verification is completed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        // go back or navigate to home/dashboard – adjust as needed
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 500),
                            child: const HomePageScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
