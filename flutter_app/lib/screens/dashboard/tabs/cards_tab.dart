import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/screens/cards/add_card_screen.dart';
import 'package:payviya_app/screens/transactions/transaction_detail_screen.dart';

class CardsTab extends StatefulWidget {
  const CardsTab({Key? key}) : super(key: key);

  @override
  State<CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<CardsTab> {
  // Mock payment methods data
  final List<Map<String, dynamic>> _cards = [
    {
      'id': 'card001',
      'type': 'credit',
      'cardType': 'Visa',
      'cardNumber': '**** **** **** 4567',
      'cardHolder': 'Ahmet Yılmaz',
      'expiryDate': '12/26',
      'backgroundColor': const Color(0xFF1E88E5),
      'isDefault': true,
      'bankName': 'Garanti BBVA',
      'bankLogo': 'assets/images/logos/garanti.png',
    },
    {
      'id': 'card002',
      'type': 'credit',
      'cardType': 'Mastercard',
      'cardNumber': '**** **** **** 8974',
      'cardHolder': 'Ahmet Yılmaz',
      'expiryDate': '09/25',
      'backgroundColor': const Color(0xFF43A047),
      'isDefault': false,
      'bankName': 'Yapı Kredi',
      'bankLogo': 'assets/images/logos/yapikredi.png',
    },
    {
      'id': 'card003',
      'type': 'debit',
      'cardType': 'Troy',
      'cardNumber': '**** **** **** 6321',
      'cardHolder': 'Ahmet Yılmaz',
      'expiryDate': '03/24',
      'backgroundColor': const Color(0xFFE53935),
      'isDefault': false,
      'bankName': 'Ziraat Bankası',
      'bankLogo': 'assets/images/logos/ziraat.png',
    },
  ];
  
  // Mock recent transactions data
  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'id': 'tx001',
      'merchantName': 'Migros',
      'merchantLogo': 'assets/images/logos/migros.png',
      'category': 'Süpermarket',
      'amount': 245.75,
      'date': '26 Mayıs 2023',
      'time': '14:30',
      'status': 'completed',
      'cardId': 'card001',
      'campaignApplied': true,
      'campaignSaving': 24.58,
    },
    {
      'id': 'tx002',
      'merchantName': 'Starbucks',
      'merchantLogo': 'assets/images/logos/starbucks.png',
      'category': 'Kafe',
      'amount': 76.50,
      'date': '25 Mayıs 2023',
      'time': '09:15',
      'status': 'completed',
      'cardId': 'card002',
      'campaignApplied': false,
      'campaignSaving': 0,
    },
    {
      'id': 'tx003',
      'merchantName': 'BP',
      'merchantLogo': 'assets/images/logos/bp.png',
      'category': 'Akaryakıt',
      'amount': 450.00,
      'date': '23 Mayıs 2023',
      'time': '17:45',
      'status': 'completed',
      'cardId': 'card001',
      'campaignApplied': true,
      'campaignSaving': 45.00,
    },
    {
      'id': 'tx004',
      'merchantName': 'Trendyol',
      'merchantLogo': 'assets/images/logos/trendyol.png',
      'category': 'E-Ticaret',
      'amount': 329.99,
      'date': '20 Mayıs 2023',
      'time': '11:20',
      'status': 'completed',
      'cardId': 'card002',
      'campaignApplied': false,
      'campaignSaving': 0,
    },
    {
      'id': 'tx005',
      'merchantName': 'MediaMarkt',
      'merchantLogo': 'assets/images/logos/mediamarkt.png',
      'category': 'Elektronik',
      'amount': 2499.90,
      'date': '18 Mayıs 2023',
      'time': '13:05',
      'status': 'completed',
      'cardId': 'card003',
      'campaignApplied': true,
      'campaignSaving': 249.99,
    },
  ];

  int _selectedCardIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Kartlarım',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: AppTheme.textPrimaryColor,
            ),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: _cards.isEmpty ? _buildEmptyState() : _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCardScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards carousel
          _buildCardsCarousel(),

          // Card details
          if (_cards.isNotEmpty) _buildCardDetails(_cards[_selectedCardIndex]),

          // Transaction history
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildCardsCarousel() {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(top: 16),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedCardIndex = index;
          });
        },
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          return _buildCreditCard(_cards[index], index);
        },
      ),
    );
  }

  Widget _buildCreditCard(Map<String, dynamic> card, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: _selectedCardIndex == index ? 0 : 12,
      ),
      decoration: BoxDecoration(
        color: card['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: card['backgroundColor'].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Card content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bank logo and card type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 30,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            card['bankLogo'],
                            errorBuilder: (context, error, stackTrace) => Text(
                              card['bankName'],
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _getCardTypeIcon(card['cardType']),
                  ],
                ),

                // Card number
                Text(
                  card['cardNumber'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Card holder and expiry date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KART SAHİBİ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['cardHolder'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SON KULLANIM',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['expiryDate'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Default card indicator
          if (card['isDefault'])
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Varsayılan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _getCardTypeIcon(String cardType) {
    Widget icon;
    switch (cardType.toLowerCase()) {
      case 'visa':
        icon = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'VISA',
            style: TextStyle(
              color: Color(0xFF1A1F71),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
        break;
      case 'mastercard':
        icon = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF5F00),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEB001B),
                ),
                margin: const EdgeInsets.only(left: -5),
              ),
            ],
          ),
        );
        break;
      case 'troy':
        icon = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'TROY',
            style: TextStyle(
              color: Color(0xFF01954D),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
        break;
      default:
        icon = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            cardType.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
    }
    return icon;
  }

  Widget _buildCardDetails(Map<String, dynamic> card) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kart Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      card['isDefault'] ? Icons.star : Icons.star_border,
                      color: card['isDefault'] ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      // Set as default card
                    },
                    tooltip: 'Varsayılan Olarak Ayarla',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onPressed: () {
                      // Edit card
                    },
                    tooltip: 'Düzenle',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Card actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCardAction(
                icon: Icons.receipt_outlined,
                label: 'Ödemeler',
                onTap: () {
                  // Navigate to payments
                },
              ),
              _buildCardAction(
                icon: Icons.lock_outlined,
                label: 'Kilitle',
                onTap: () {
                  // Lock card
                },
              ),
              _buildCardAction(
                icon: Icons.local_offer_outlined,
                label: 'Kampanyalar',
                onTap: () {
                  // View card campaigns
                },
              ),
              _buildCardAction(
                icon: Icons.delete_outline,
                label: 'Kaldır',
                onTap: () {
                  // Remove card
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son İşlemler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // View all transactions
                },
                child: const Text(
                  'Tümünü Gör',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _recentTransactions.isEmpty
              ? _buildEmptyTransactions()
              : Column(
                  children: _recentTransactions
                      .take(3)
                      .map((tx) => _buildTransactionItem(tx))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    // Find card details for this transaction
    final card = _cards.firstWhere(
      (card) => card['id'] == transaction['cardId'],
      orElse: () => _cards.first,
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
              card: card,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Merchant logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                transaction['merchantLogo'],
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.store,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction['merchantName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '₺${transaction['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction['category'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${transaction['date']} ${transaction['time']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Card info
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: card['backgroundColor'],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${card['bankName']} ${card['cardType']}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Campaign savings
                      if (transaction['campaignApplied'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.savings_outlined,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '₺${transaction['campaignSaving'].toStringAsFixed(2)} Tasarruf',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz kart eklenmedi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Kart ekleyerek hemen kampanyalara katılmaya başlayın ve tasarruf edin',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddCardScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Kart Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz işlem yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kartınızla yapacağınız ilk harcama burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 