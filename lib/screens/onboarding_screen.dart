import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/model_manager.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Welcome to Voice AI',
      description: 'Transform your voice recordings into actionable insights with advanced AI technology.',
      icon: Icons.record_voice_over,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Offline Processing',
      description: 'All processing happens on your device. Your data never leaves your phone, ensuring complete privacy.',
      icon: Icons.phone_android,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Smart Analysis',
      description: 'Get emotion analysis, automatic summaries, task extraction, and formatted meeting minutes.',
      icon: Icons.analytics,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Ready to Start',
      description: 'AI models will be downloaded automatically when needed. Your privacy is protected with local processing.',
      icon: Icons.security,
      color: Colors.purple,
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index], theme);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildPageIndicator(),
                  const SizedBox(height: 32),
                  _buildNavigationButtons(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPage(OnboardingPage page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.color,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? pages[_currentPage].color
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate().scale(
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
      ),
    );
  }
  
  Widget _buildNavigationButtons(ThemeData theme) {
    final isLastPage = _currentPage == pages.length - 1;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _currentPage > 0
              ? () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: isLastPage ? _onGetStarted : _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: pages[_currentPage].color,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            isLastPage ? 'Get Started' : 'Next',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
  
  void _onNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  Future<void> _onGetStarted() async {
    try {
      // Mark as not first run
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_run', false);
      
      if (mounted) {
        // Show loading and initialize models
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ModelInitializationDialog(),
        );
        
        // Initialize models
        await ModelManager.instance.initializeModels(
          context: context,
        );
        
        // Close dialog and navigate to home
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Navigate to home anyway
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ModelInitializationDialog extends StatelessWidget {
  const ModelInitializationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Setting up AI Models',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Downloading required models for speech recognition...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}