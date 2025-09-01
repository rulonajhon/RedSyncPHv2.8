import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      int next = _controller.page?.round() ?? 0;
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNextPage() async {
    if (_currentPage < 5) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Set onboarding complete flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      if (!mounted) return; // Ensure context is still valid
      Navigator.pushReplacementNamed(context, '/authentication');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              children: [
                const OnboardingPanel(
                  textTitle: 'Welcome to RedSyncPH',
                  textSubTitle:
                      'Your all-in-one solution for managing hemophilia care.',
                  imagePath: 'assets/images/app_logo.png',
                ),
                const OnboardingPanel(
                  textTitle: 'Easy Health Tracking',
                  textSubTitle:
                      'Log bleeding episodes and medications with just a few steps',
                  imagePath: 'assets/images/Onboard_img_healthTrack.jpg',
                ),
                const OnboardingPanel(
                  textTitle: 'Smart Dosage Calculator',
                  textSubTitle:
                      'Get Accurate clotthing factor calculations based on your weight and conditions',
                  imagePath: 'assets/images/Onboard_img_calculator.jpg',
                ),
                const OnboardingPanel(
                  textTitle: 'Treatment Reminders',
                  textSubTitle:
                      'Never miss a dose with smart, customizable reminders.',
                  imagePath: 'assets/images/Onboard_img_reminder.jpg',
                ),
                const OnboardingPanel(
                  textTitle: 'Locate Healthcare Providers',
                  textSubTitle: 'Find the best healthcare providers near you.',
                  imagePath: 'assets/images/Onboard_img_calculator.jpg',
                ),
                const OnboardingPanel(
                  textTitle: 'Learn & Connect',
                  textSubTitle:
                      'Connect with others and learn more about hemophilia.',
                  imagePath: 'assets/images/Onboard_img_calculator.jpg',
                ),
              ],
            ),
            // Bottom-aligned indicator and button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SmoothPageIndicator(
                        effect: const ExpandingDotsEffect(
                          dotColor: Color.fromARGB(255, 199, 199, 199),
                          activeDotColor: Colors.red,
                          dotHeight: 10,
                          dotWidth: 10,
                          spacing: 8.0,
                        ),
                        controller: _controller,
                        count: 6,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _goToNextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(150, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            _currentPage == 5 ? "Get Started" : "Next",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPanel extends StatelessWidget {
  const OnboardingPanel({
    super.key,
    required this.textTitle,
    required this.textSubTitle,
    required this.imagePath,
  });

  final String textTitle;
  final String textSubTitle;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image
            Image.asset(imagePath),

            const SizedBox(height: 16),

            // Welcome Text
            Text(
              textTitle,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description Text
            Text(
              textSubTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
