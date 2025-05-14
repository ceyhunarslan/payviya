import 'package:flutter/material.dart';
import 'package:payviya_app/models/credit_card.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/theme/app_theme.dart';

class AddCardModal extends StatefulWidget {
  final Function() onCardsAdded;
  final List<CreditCardListItem> existingCards;

  const AddCardModal({
    super.key,
    required this.onCardsAdded,
    required this.existingCards,
  });

  @override
  State<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends State<AddCardModal> {
  bool _isLoading = true;
  List<CreditCardListItem> _availableCards = [];
  Set<int> _selectedCardIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch only available cards
      final availableResponse = await ApiService.instance.dio.get('/credit-cards/');
      
      if (mounted) {
        // Parse available cards
        final allCards = (availableResponse.data as List).map((card) => CreditCardListItem(
          id: card['credit_card_id'],
          creditCardId: card['credit_card_id'],
          creditCardName: card['credit_card_name'],
          creditCardLogoUrl: card['credit_card_logo_url'],
          bankName: card['bank_name'],
          bankLogoUrl: card['bank_logo_url'],
        )).toList();

        // Get set of user's card IDs for easy comparison
        final userCardIds = widget.existingCards.map((c) => c.creditCardId).toSet();

        // Filter out cards that user already has
        final availableCards = allCards.where((card) => !userCardIds.contains(card.creditCardId)).toList();

        setState(() {
          _availableCards = availableCards;
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
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kartlar başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Call the callback to refresh cards list
        widget.onCardsAdded();
        
        // Close the modal after a short delay to ensure the snackbar is visible
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
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

  Widget _buildCardItem(CreditCardListItem card, {bool isDisabled = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDisabled
              ? Colors.grey.withOpacity(0.2)
              : _selectedCardIds.contains(card.creditCardId)
                  ? AppTheme.primaryColor
                  : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          '${card.bankName} - ${card.creditCardName}',
          style: TextStyle(
            color: isDisabled ? Colors.grey : AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: isDisabled ? true : _selectedCardIds.contains(card.creditCardId),
        onChanged: isDisabled ? null : (bool? value) {
          setState(() {
            if (value == true) {
              _selectedCardIds.add(card.creditCardId);
            } else {
              _selectedCardIds.remove(card.creditCardId);
            }
          });
        },
        activeColor: isDisabled ? Colors.grey : AppTheme.primaryColor,
        checkColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Yeni Kart Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppTheme.textPrimaryColor,
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              // Card lists
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Available cards section
                    if (_availableCards.isNotEmpty) ...[
                      const Text(
                        'Seçilebilecek Kartlar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._availableCards.map((card) => _buildCardItem(card)),
                      const SizedBox(height: 24),
                    ],

                    // User's existing cards section
                    if (widget.existingCards.isNotEmpty) ...[
                      const Text(
                        'Mevcut Kartlarınız',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.existingCards.map((card) => _buildCardItem(card, isDisabled: true)),
                    ],
                  ],
                ),
              ),

            // Save button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _availableCards.isEmpty ? null : _saveSelectedCards,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _availableCards.isEmpty 
                              ? 'Seçilebilecek Kart Bulunmuyor'
                              : 'Kartları Kaydet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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