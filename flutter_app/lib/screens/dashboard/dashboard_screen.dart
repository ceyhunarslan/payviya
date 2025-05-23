import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/campaigns/campaign_discovery_screen.dart';
import 'package:payviya_app/screens/dashboard/tabs/cards_tab.dart';
import 'package:payviya_app/screens/dashboard/tabs/home_tab.dart';
import 'package:payviya_app/screens/dashboard/tabs/profile_tab.dart';
import 'package:payviya_app/services/navigation_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:payviya_app/widgets/user_avatar.dart';
import 'package:payviya_app/screens/notifications/notifications_screen.dart';
import 'package:payviya_app/widgets/notification_icon_with_badge.dart';
import 'package:payviya_app/services/auth_service.dart';
import 'package:payviya_app/services/location_service.dart';
import 'package:payviya_app/services/campaign_service.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const DashboardScreen({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  static final GlobalKey<DashboardScreenState> globalKey = GlobalKey<DashboardScreenState>();

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late int _currentIndex;
  String _userName = '';
  String _userSurname = '';
  late LocationService _locationService;

  final List<String> _tabTitles = [
    'Ana Sayfa',
    'Kampanyalar',
    'Kartlarım',
    'Profil',
  ];

  // Add a getter to check if we should show header elements
  bool get _shouldShowHeaderElements => _currentIndex != 1; // Hide for Campaign Discovery (index 1)

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _currentIndex = widget.initialTabIndex;
    _loadUserData();
    _initializeServices();
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    super.dispose();
  }

  void onTabTapped(int index) {
    if (!mounted) return;

    setState(() => _currentIndex = index);
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await UserService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userName = userData?.name ?? 'User';
          _userSurname = userData?.surname ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Update FCM token
      await AuthService.updateFCMToken();
      
      // Initialize location service
      final hasPermission = await _locationService.handlePermission();
      if (hasPermission) {
        _locationService.startLocationTracking((position) {
          // Handle location updates
          print('📌 Location update received: ${position.latitude}, ${position.longitude}');
        });
      }
      
      // Initialize campaign service
      await CampaignService.initialize();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  final List<Widget> _tabs = [
    const HomeTab(),
    const CampaignDiscoveryScreen(showAppBar: false),
    const CardsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          onTabTapped(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: _currentIndex == 1
          ? const CampaignDiscoveryScreen()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  snap: false,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  toolbarHeight: 56,
                  automaticallyImplyLeading: false,
                  primary: true,
                  forceElevated: innerBoxIsScrolled,
                  title: Row(
                    children: [
                      UserAvatar(
                        name: _userName,
                        surname: _userSurname,
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor,
                        textColor: Colors.white,
                        fontSize: 16,
                        enableTap: true,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _tabTitles[_currentIndex],
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  actions: const [
                    NotificationIconWithBadge(),
                    SizedBox(width: 8),
                  ],
                ),
              ],
              body: IndexedStack(
                index: _currentIndex > 1 ? _currentIndex - 1 : _currentIndex,
                children: [
                  PageStorage(
                    bucket: PageStorageBucket(),
                    child: const HomeTab(key: PageStorageKey('home_tab')),
                  ),
                  PageStorage(
                    bucket: PageStorageBucket(),
                    child: const CardsTab(key: PageStorageKey('cards_tab')),
                  ),
                  PageStorage(
                    bucket: PageStorageBucket(),
                    child: const ProfileTab(key: PageStorageKey('profile_tab')),
                  ),
                ],
              ),
            ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'Kampanyalar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: 'Kartlarım',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildQuickActionsSheet(),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildQuickActionsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Row(
                  children: [
                    const Text(
                      "Hızlı İşlemler",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "PayViya'nın sunduğu özelleştirilmiş hizmetlere hızlı erişim",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action grid
              Expanded(
                child: GridView.count(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard(
                      "Öneri Al",
                      "Alışveriş sepetinize göre kartlar",
                      Icons.lightbulb_rounded,
                      const Color(0xFF3A86FF),
                      () {
                        Navigator.pop(context);
                        // Navigate to recommendation screen
                      },
                    ),
                    _buildActionCard(
                      "QR Tara",
                      "Mağaza kampanyaları için QR tara",
                      Icons.qr_code_scanner_rounded,
                      const Color(0xFF6B62FE),
                      () {
                        Navigator.pop(context);
                        // Open QR scanner
                      },
                    ),
                    _buildActionCard(
                      "Yeni Kart",
                      "Yeni kart başvurusu yap",
                      Icons.add_card_rounded,
                      const Color(0xFF447CD4),
                      () {
                        Navigator.pop(context);
                        // Navigate to card application
                      },
                    ),
                    _buildActionCard(
                      "Kampanya Bul",
                      "Kategorilere göre ara",
                      Icons.search_rounded,
                      const Color(0xFF4A86E8),
                      () {
                        Navigator.pop(context);
                        // Navigate to campaign search
                      },
                    ),
                    _buildActionCard(
                      "Banka Bağla",
                      "Hesaplarını PayViya'ya bağla",
                      Icons.account_balance_rounded,
                      const Color(0xFF4CAF50),
                      () {
                        Navigator.pop(context);
                        // Navigate to bank connection
                      },
                    ),
                    _buildActionCard(
                      "Arkadaş Davet Et",
                      "Arkadaşlarını davet et, bonus kazan",
                      Icons.people_alt_rounded,
                      const Color(0xFFFF6B6B),
                      () {
                        Navigator.pop(context);
                        // Navigate to referral screen
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 