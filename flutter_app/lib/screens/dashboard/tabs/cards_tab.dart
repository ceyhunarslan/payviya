import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/credit_card.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/widgets/add_card_modal.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:payviya_app/utils/logo_helper.dart';
import 'package:payviya_app/widgets/user_avatar.dart';
import 'package:payviya_app/widgets/notification_icon_with_badge.dart';

class CardsTab extends StatefulWidget {
  const CardsTab({super.key});

  @override
  State<CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<CardsTab> {
  List<CreditCardListItem> _cards = [];
  bool _isLoading = true;
  String _userName = '';
  String _userSurname = '';
  int _selectedCardIndex = 0;  // Track the currently selected card

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await UserService.getCurrentUser();
      final cards = await ApiService.getUserCards();
      
      if (mounted) {
        setState(() {
          _userName = userData?.name ?? 'User';
          _userSurname = userData?.surname ?? '';
          _cards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kartlar yüklenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedCard() async {
    if (_cards.isEmpty) return;

    try {
      final cardToDelete = _cards[_selectedCardIndex];
      
      // Check if the card ID exists
      if (cardToDelete.id == null) {
        throw Exception('Card ID is missing');
      }

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kartı Sil'),
          content: Text('${cardToDelete.creditCardName} kartını silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sil'),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      // Show loading indicator
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Delete the card using user_credit_cards.id
      await ApiService.instance.deleteUserCard(cardToDelete.id!);

      // Reload the cards list
      await _loadData();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kart başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );

        // Update selected card index if necessary
        setState(() {
          if (_selectedCardIndex >= _cards.length) {
            _selectedCardIndex = _cards.isEmpty ? 0 : _cards.length - 1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kart silinirken bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: Colors.white,
              elevation: 0,
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
                  const Expanded(
                    child: Text(
                      'Kartlarım',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const NotificationIconWithBadge(),
                ],
              ),
            ),
            SliverFillRemaining(
              child: _buildEmptyState(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: _cards.length,
                      controller: PageController(viewportFraction: 0.9),
                      onPageChanged: (index) {
                        setState(() {
                          _selectedCardIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return _buildCardItem(card);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCardOperations(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(CreditCardListItem card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.primaryColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Bank Logo
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LogoHelper.getBankLogoWidget(
                    card.bankName,
                    card.bankLogoUrl,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Card Logo
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LogoHelper.getCardLogoWidget(
                    card.creditCardName,
                    card.creditCardLogoUrl,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Card Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.bankName ?? 'Bilinmeyen Banka',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.creditCardName ?? 'Bilinmeyen Kart',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
              'Henüz kart seçilmedi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Seçeceğin kartlara özel kampanyaları sana göstereceğiz.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Merak etme, kart bilgilerin sana özeldir ve onları senden istemeyeceğiz. Seçeceğin kartlara ait kampanyaları Bana Özel ekranında görebileceksin, hepsi bu :)',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddCardModal(
                    onCardsAdded: _loadData,
                    existingCards: _cards,
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
                minimumSize: const Size(240, 48),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_card),
                  SizedBox(width: 8),
                  Text('Kart Seç'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOperations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kart İşlemleri',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddCardModal(
                        onCardsAdded: _loadData,
                        existingCards: _cards,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_card),
                  label: const Text('Kart Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cards.isEmpty ? null : _deleteSelectedCard,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Kartı Sil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to campaigns screen
                  },
                  icon: const Icon(Icons.local_offer_outlined),
                  label: const Text('Kampanyalar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 