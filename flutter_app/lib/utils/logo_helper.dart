import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class LogoHelper {
  // Map bank names to local asset paths
  static final Map<String, String> bankLogoMap = {
    'Garanti BBVA': 'assets/images/logos/banks/garanti_bbva.png',
    'Akbank': 'assets/images/logos/banks/akbank.png',
    'İş Bankası': 'assets/images/logos/banks/is_bankasi.png',
    'Yapı Kredi': 'assets/images/logos/banks/yapi_kredi.png',
    'QNB': 'assets/images/logos/banks/qnb.png',
    'Ziraat Bankası': 'assets/images/logos/banks/ziraat.png',
    'Halkbank': 'assets/images/logos/banks/halkbank.png',
    'Vakıfbank': 'assets/images/logos/banks/vakifbank.png',
    'TEB': 'assets/images/logos/banks/teb.png',
    'HSBC': 'assets/images/logos/banks/hsbc.png',
    'Denizbank': 'assets/images/logos/banks/denizbank.png',
    'ING': 'assets/images/logos/banks/ing.png',
    'Odeabank': 'assets/images/logos/banks/odeabank.png',
    'Şekerbank': 'assets/images/logos/banks/sekerbank.png',
    'Fibabanka': 'assets/images/logos/banks/fibabanka.png',
    // Add more banks as needed
  };

  // Map card names to local asset paths
  static final Map<String, String> cardLogoMap = {
    'Bonus Card': 'assets/images/logos/cards/bonus_card.png',
    'Axess': 'assets/images/logos/cards/axess.png',
    'Maximum': 'assets/images/logos/cards/maximum.png',
    'World': 'assets/images/logos/cards/worldcard.png',
    'Vakıfbank World Card': 'assets/images/logos/cards/vakif_worldcard.png',
    'QNB': 'assets/images/logos/cards/qnb.png',
    'Bankkart': 'assets/images/logos/cards/bankkart.png',
    'Paraf': 'assets/images/logos/cards/paraf.png',
    'TEB Bonus': 'assets/images/logos/cards/teb_bonus.png',
    'Advantage': 'assets/images/logos/cards/hsbc_advantage.png',
    'Denizbank Bonus': 'assets/images/logos/cards/denizbank_bonus.png',
    'ING Card': 'assets/images/logos/cards/ing_card.png',
    'Bank O Card': 'assets/images/logos/cards/bank_o_card.png',
    'Şeker Bonus': 'assets/images/logos/cards/seker_bonus.png',
    'Fibabanka Card': 'assets/images/logos/cards/fibabanka_card.png',
    // Add more cards as needed
  };

  // Get the appropriate logo widget
  static Widget getBankLogoWidget(String? bankName, String? logoUrl, {double size = 40}) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      // Use the remote URL first if available
      return Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _getLocalOrFallbackLogo(bankName ?? 'Unknown Bank', size),
      );
    } else {
      // Try local asset or fallback to first letter
      return _getLocalOrFallbackLogo(bankName ?? 'Unknown Bank', size);
    }
  }

  // Get the appropriate logo widget for a card
  static Widget getCardLogoWidget(String? cardName, String? logoUrl, {double size = 40}) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      // Use the remote URL first if available
      return Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _getLocalOrFallbackCardLogo(cardName ?? 'Unknown Card', size),
      );
    } else {
      // Try local asset or fallback to first letter
      return _getLocalOrFallbackCardLogo(cardName ?? 'Unknown Card', size);
    }
  }

  // Helper to get local asset or fallback for banks
  static Widget _getLocalOrFallbackLogo(String bankName, double size) {
    // Try to get a local asset
    if (bankLogoMap.containsKey(bankName)) {
      // Create high-resolution image with proper error handling
      return _createHighResolutionImage(
        bankLogoMap[bankName]!,
        size,
        () => _generatePlaceholderLogo(bankName, size, true),
      );
    } else {
      // Fall back to a generated placeholder
      return _generatePlaceholderLogo(bankName, size, true);
    }
  }

  // Helper to get local asset or fallback for cards
  static Widget _getLocalOrFallbackCardLogo(String cardName, double size) {
    // Try to get a local asset
    if (cardLogoMap.containsKey(cardName)) {
      // Create high-resolution image with proper error handling
      return _createHighResolutionImage(
        cardLogoMap[cardName]!,
        size,
        () => _generatePlaceholderLogo(cardName, size, false),
      );
    } else {
      // Fall back to a generated placeholder
      return _generatePlaceholderLogo(cardName, size, false);
    }
  }

  // Create a high-resolution image with error handling
  static Widget _createHighResolutionImage(String assetPath, double size, Widget Function() fallbackWidget) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * 2).toInt(), // Request a higher resolution for sharper rendering
      errorBuilder: (context, error, stackTrace) {
        print('Error loading asset: $assetPath - $error');
        return fallbackWidget();
      },
    );
  }

  // Generate a better-looking placeholder logo
  static Widget _generatePlaceholderLogo(String name, double size, bool isBank) {
    final Color backgroundColor = _getColorFromName(name);
    final String label = name.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 8),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          label.length > 2 ? label.substring(0, 2) : label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size / 2.5,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get a fallback logo with the first letter of the name
  static Widget _getFallbackLogo(String name, double size) {
    return _generatePlaceholderLogo(name, size, false);
  }

  // Generate a consistent color from a name
  static Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.blue;
    
    // Simple hash function to generate a consistent color
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convert to color
    final red = ((hash & 0xFF0000) >> 16);
    final green = ((hash & 0x00FF00) >> 8);
    final blue = (hash & 0x0000FF);
    
    return Color.fromARGB(255, 
      red.abs() % 200 + 55,  // Keep it not too dark
      green.abs() % 200 + 55,
      blue.abs() % 200 + 55);
  }

  static String getBankLogo(String bankName) {
    final normalizedName = bankName.toLowerCase().replaceAll(' ', '_');
    
    switch (normalizedName) {
      case 'garanti_bbva':
        return 'assets/images/logos/banks/garanti_bbva.png';
      case 'akbank':
        return 'assets/images/logos/banks/akbank.png';
      case 'is_bankasi':
      case 'iş_bankası':
        return 'assets/images/logos/banks/is_bankasi.png';
      case 'yapi_kredi':
      case 'yapı_kredi':
        return 'assets/images/logos/banks/yapi_kredi.png';
      case 'qnb':
      case 'qnb_finansbank':
        return 'assets/images/logos/banks/qnb_finansbank.png';
      case 'ziraat_bankası':
      case 'ziraat_bankasi':
        return 'assets/images/logos/banks/ziraat.png';
      case 'halkbank':
        return 'assets/images/logos/banks/halkbank.png';
      case 'vakıfbank':
      case 'vakifbank':
        return 'assets/images/logos/banks/vakifbank.png';
      case 'teb':
        return 'assets/images/logos/banks/teb.png';
      case 'hsbc':
        return 'assets/images/logos/banks/hsbc.png';
      case 'denizbank':
        return 'assets/images/logos/banks/denizbank.png';
      case 'ing':
        return 'assets/images/logos/banks/ing.png';
      case 'odeabank':
        return 'assets/images/logos/banks/odeabank.png';
      case 'şekerbank':
      case 'sekerbank':
        return 'assets/images/logos/banks/sekerbank.png';
      case 'fibabanka':
        return 'assets/images/logos/banks/fibabanka.png';
      default:
        return 'assets/images/placeholder.png';
    }
  }

  static String getCardLogo(String cardName) {
    final normalizedName = cardName.toLowerCase().replaceAll(' ', '_');
    
    switch (normalizedName) {
      case 'bonus_card':
      case 'bonus':
        return 'assets/images/logos/cards/bonus_card.png';
      case 'maximum':
        return 'assets/images/logos/cards/maximum.png';
      case 'axess':
        return 'assets/images/logos/cards/axess.png';
      case 'world':
      case 'worldcard':
        return 'assets/images/logos/cards/worldcard.png';
      case 'qnb_kredi_kartı':
      case 'qnb_kredi_karti':
        return 'assets/images/logos/cards/qnb.png';
      case 'bankkart':
        return 'assets/images/logos/cards/bankkart.png';
      case 'paraf':
        return 'assets/images/logos/cards/paraf.png';
      case 'teb_bonus':
        return 'assets/images/logos/cards/teb_bonus.png';
      case 'advance':
      case 'hsbc_advance':
        return 'assets/images/logos/cards/hsbc_advance.png';
      case 'denizbank_bonus':
        return 'assets/images/logos/cards/denizbank_bonus.png';
      case 'ing_card':
        return 'assets/images/logos/cards/ing_card.png';
      case 'bank_o_card':
        return 'assets/images/logos/cards/bank_o_card.png';
      case 'şeker_bonus':
      case 'seker_bonus':
        return 'assets/images/logos/cards/seker_bonus.png';
      case 'fibabanka_card':
        return 'assets/images/logos/cards/fibabanka_card.png';
      default:
        return 'assets/images/placeholder.png';
    }
  }
} 