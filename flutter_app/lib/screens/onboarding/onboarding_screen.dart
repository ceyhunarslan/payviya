import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "En İyi Ödeme Yöntemini Bul",
      description: "Alışveriş yaparken, alışveriş sepetinize göre en avantajlı ödeme yöntemini anında görün.",
      image: "assets/images/onboarding1.png",
      color: AppTheme.primaryColor,
      icon: Icons.account_balance_wallet_outlined,
    ),
    OnboardingPage(
      title: "Kampanyaları Kaçırma",
      description: "Bankalar ve kredi kartları tarafından sunulan tüm özel fırsatları ve indirimleri tek yerden takip edin.",
      image: "assets/images/onboarding2.png",
      color: AppTheme.chartPrimary,
      icon: Icons.local_offer_outlined,
    ),
    OnboardingPage(
      title: "Anında Başvuru Yap",
      description: "Daha iyi fırsatlar sunan yeni kredi kartlarına anında başvurun ve hemen kullanmaya başlayın.",
      image: "assets/images/onboarding3.png",
      color: AppTheme.mediumBlue,
      icon: Icons.credit_card_outlined,
    ),
    OnboardingPage(
      title: "Tasarruflarınızı Görün",
      description: "PayViya ile ne kadar tasarruf ettiğinizi takip edin ve finansal kararlarınızı daha bilinçli verin.",
      image: "assets/images/onboarding4.png",
      color: AppTheme.secondaryColor,
      icon: Icons.savings_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _onSkipPressed() {
    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _onSkipPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondaryColor,
                  ),
                  child: const Text(
                    "Atla",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Page indicator and next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDotIndicator(index),
                    ),
                  ),
                  
                  // Next button
                  SizedBox(
                    width: 120, // Fixed width for the button
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                        shadowColor: _pages[_currentPage].color.withOpacity(0.3),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? "Başla" : "İleri",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or illustration
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: 120,
                color: page.color,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    bool isActive = index == _currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? _pages[_currentPage].color : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  IconData _getIconForPage(OnboardingPage page) {
    return page.icon;
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    required this.icon,
  });
} 