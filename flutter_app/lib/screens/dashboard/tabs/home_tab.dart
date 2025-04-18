import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/widgets/campaign_card.dart';
import 'package:payviya_app/widgets/savings_chart.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Mock data
  final bool _hasCards = true; // Mock flag to determine if user has saved cards
  
  final Map<String, dynamic> _lastCaughtCampaign = {
    'id': 1,
    'bankName': 'TürkBank',
    'cardName': 'Cash Rewards Platinum',
    'discount': '15%',
    'category': 'Groceries',
    'expiry': '31 Aralık 2023',
    'logoUrl': 'assets/images/bank1.png',
    'color': const Color(0xFF3A86FF),
    'timestamp': '2 saat önce',
  };
  
  final Map<String, dynamic> _bestRecommendation = {
    'id': 2,
    'bankName': 'FinansBank',
    'cardName': 'Shopping Card',
    'discount': '25%',
    'category': 'Electronics',
    'expiry': '15 Kasım 2023',
    'logoUrl': 'assets/images/bank2.png',
    'color': const Color(0xFF9D4EDD),
  };
  
  final Map<String, dynamic> _bestCampaign = {
    'id': 3,
    'bankName': 'DigiBank',
    'cardName': 'Max Rewards',
    'discount': '30%',
    'category': 'Restaurants',
    'expiry': '10 Aralık 2023',
    'logoUrl': 'assets/images/bank3.png',
    'color': const Color(0xFF5E60CE),
  };
  
  final List<Map<String, dynamic>> _todaysCampaigns = [
    {
      'id': 4,
      'bankName': 'AkBank',
      'cardName': 'Wings Kart',
      'discount': '10%',
      'category': 'Travel',
      'expiry': '1 Ocak 2024',
      'logoUrl': 'assets/images/bank4.png',
      'color': const Color(0xFF72DDF7),
    },
    {
      'id': 5,
      'bankName': 'YapıKredi',
      'cardName': 'World Elite',
      'discount': '150 TL',
      'category': 'Fashion',
      'expiry': '5 Aralık 2023',
      'logoUrl': 'assets/images/bank5.png',
      'color': const Color(0xFFF8961E),
    },
  ];

  // Total campaign count
  final int _totalCampaignCount = 35;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              automaticallyImplyLeading: false,
              floating: true,
              pinned: false,
              snap: false,
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    radius: 18,
                    child: Text(
                      "C",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Merhaba, Ceyhun",
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.textPrimaryColor,
                  ),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // 1. Last caught campaign (En son yakalanan kampanya)
                    _buildSectionTitle('En Son Yakalanan Kampanya'),
                    _buildLastCaughtCampaign(),
                    
                    const SizedBox(height: 24),
                    
                    // 2. Total campaign count info
                    _buildTotalCampaignInfo(),
                    
                    const SizedBox(height: 24),
                    
                    // 3. Best campaign/Best recommendation (En iyi teklif) 
                    _buildSectionTitle('En İyi Teklif'),
                    _buildBestOffer(),
                    
                    const SizedBox(height: 24),
                    
                    // 4. Today's campaigns (Bugünkü Fırsatlar)
                    _buildSectionTitle('Bugünkü Fırsatlar'),
                    _buildTodaysCampaigns(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            'Tümünü Gör',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLastCaughtCampaign() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CampaignCard(
                  bankName: _lastCaughtCampaign['bankName'],
                  cardName: _lastCaughtCampaign['cardName'],
                  discount: _lastCaughtCampaign['discount'],
                  category: _lastCaughtCampaign['category'],
                  expiry: _lastCaughtCampaign['expiry'],
                  color: _lastCaughtCampaign['color'],
                  width: double.infinity,
                  onTap: () {
                    // Navigate to campaign detail
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Yakalandı: ${_lastCaughtCampaign['timestamp']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTotalCampaignInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_totalCampaignCount kampanya',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'senin için burada!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildBestOffer() {
    // Show best recommendation if user has saved cards, otherwise show best campaign
    final offerData = _hasCards ? _bestRecommendation : _bestCampaign;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CampaignCard(
                  bankName: offerData['bankName'],
                  cardName: offerData['cardName'],
                  discount: offerData['discount'],
                  category: offerData['category'],
                  expiry: offerData['expiry'],
                  color: offerData['color'],
                  width: double.infinity,
                  onTap: () {
                    // Navigate to campaign detail
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _hasCards ? Icons.recommend_rounded : Icons.star_rate_rounded,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasCards 
                    ? 'Kartlarınıza göre özelleştirilmiş öneri'
                    : 'En yüksek indirim oranına sahip kampanya',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodaysCampaigns() {
    return Column(
      children: _todaysCampaigns.map((campaign) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CampaignCard(
              bankName: campaign['bankName'],
              cardName: campaign['cardName'],
              discount: campaign['discount'],
              category: campaign['category'],
              expiry: campaign['expiry'],
              color: campaign['color'],
              width: double.infinity,
              onTap: () {
                // Navigate to campaign detail
              },
            ),
          ),
        )
      ).toList(),
    );
  }
} 