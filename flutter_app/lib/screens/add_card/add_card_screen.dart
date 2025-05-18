import 'package:flutter/material.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/user_service.dart';
import 'package:payviya_app/theme/app_theme.dart';
import 'package:payviya_app/widgets/notification_icon_with_badge.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _isLoading = true;
  String _userName = '';
  List<CreditCard> _availableCards = [];
  Set<int> _selectedCardIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await UserService.getCurrentUser();
      final response = await ApiService.instance.dio.get('/credit-cards/');
      
      if (mounted) {
        setState(() {
          _userName = userData?.name ?? 'User';
          _availableCards = (response.data as List).map((card) => CreditCard(
            id: card['credit_card_id'],
            bankName: card['bank_name'],
            cardName: card['credit_card_name'],
            cardLogoUrl: card['credit_card_logo_url'],
            bankLogoUrl: card['bank_logo_url'],
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cards: $e');
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

  Future<void> _saveSelectedCards() async {
    if (_selectedCardIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir kart seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await ApiService.instance.dio.post(
        '/users/me/cards',
        data: {
          'card_ids': _selectedCardIds.toList(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kartlar başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error saving cards: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kartlar eklenirken bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Banner with avatar and notification
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    radius: 18,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const NotificationIconWithBadge(),
                ],
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Text(
                'Yeni Kart Ekle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              // Card list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _availableCards.length,
                  itemBuilder: (context, index) {
                    final card = _availableCards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedCardIds.contains(card.id)
                              ? AppTheme.primaryColor
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          '${card.bankName} - ${card.cardName}',
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _selectedCardIds.contains(card.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedCardIds.add(card.id);
                            } else {
                              _selectedCardIds.remove(card.id);
                            }
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                        checkColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    );
                  },
                ),
              ),

            // Save button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSelectedCards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Kartları Ekle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

class CreditCard {
  final int id;
  final String bankName;
  final String cardName;
  final String cardLogoUrl;
  final String bankLogoUrl;

  CreditCard({
    required this.id,
    required this.bankName,
    required this.cardName,
    required this.cardLogoUrl,
    required this.bankLogoUrl,
  });
} 