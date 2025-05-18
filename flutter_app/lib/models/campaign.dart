enum DiscountType {
  PERCENTAGE,
  CASHBACK,
  POINTS,
  FIXED
}

enum CampaignSource {
  MANUAL,
  AUTOMATIC,
  API
}

class Campaign {
  final int id;
  final String name;
  final String _description;
  final String category;
  final String? categoryName;
  final int? categoryId;
  final DiscountType? discountType;
  final double? discountValue;
  final double minAmount;
  final double? maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final int priority;
  final int? merchantId;
  final bool isActive;
  final Bank? bank;
  final CreditCard? creditCard;
  final bool requiresEnrollment;
  final String? enrollmentUrl;
  final Merchant? merchant;
  final CampaignSource source;

  Campaign({
    required this.id,
    required this.name,
    required String description,
    required this.category,
    this.categoryName,
    this.categoryId,
    this.discountType,
    this.discountValue,
    this.minAmount = 0.0,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.priority,
    this.merchantId,
    required this.isActive,
    this.bank,
    this.creditCard,
    required this.requiresEnrollment,
    this.enrollmentUrl,
    this.merchant,
    this.source = CampaignSource.MANUAL,
  }) : _description = description;

  // Getters
  String get description => _description;
  int? get merchant_id => merchantId;  // Add getter for merchant_id

  factory Campaign.fromJson(Map<String, dynamic> json) {
    try {
      print('JSON data: $json');
      
      // Handle bank object
      Bank? bank;
      if (json['bank'] is Map) {
        bank = Bank.fromJson(json['bank'] as Map<String, dynamic>);
      } else if (json['bank_id'] != null) {
        bank = Bank(
          id: json['bank_id'] as int,
          name: json['bank_name'] as String? ?? 'Unknown Bank',
          logoUrl: null,
        );
      }
      
      // Handle credit card object
      CreditCard? creditCard;
      if (json['credit_card'] is Map) {
        creditCard = CreditCard.fromJson(json['credit_card'] as Map<String, dynamic>);
      } else if (json['card_id'] != null) {
        creditCard = CreditCard(
          id: json['card_id'] as int,
          name: json['card_name'] as String? ?? 'Unknown Card',
          bankId: json['bank_id'] as int,
          cardType: 'unknown',
          cardTier: 'standard',
          applicationUrl: json['credit_card_application_url'] as String?,
          isActive: true,
        );
      }
      
      // Handle merchant object
      Merchant? merchant;
      if (json['merchant'] is Map) {
        try {
          final merchantData = json['merchant'] as Map<String, dynamic>;
          merchant = Merchant(
            id: merchantData['id'] as int? ?? 0,
            name: merchantData['name'] as String? ?? 'Unknown Merchant',
            categories: merchantData['categories'] as String? ?? '',
            logoUrl: merchantData['logo_url'] as String? ?? '',
          );
        } catch (e) {
          print('Error parsing merchant data: $e');
          // Create a default merchant if parsing fails
          merchant = Merchant(
            id: json['merchant_id'] as int? ?? 0,
            name: 'Unknown Merchant',
            categories: '',
            logoUrl: null,
          );
        }
      } else if (json['merchant_id'] != null) {
        merchant = Merchant(
          id: json['merchant_id'] as int? ?? 0,
          name: json['merchant_name'] as String? ?? 'Unknown Merchant',
          categories: '',
          logoUrl: null,
        );
      }

      // Parse discount type
      DiscountType? discountType;
      if (json['discount_type'] != null) {
        try {
          String discountTypeStr = (json['discount_type'] as String? ?? '')
            .replaceFirst('DISCOUNTTYPE.', '') // Remove prefix if exists
            .replaceFirst('DiscountType.', ''); // Remove another possible prefix
          discountType = DiscountType.values.firstWhere(
            (e) => e.toString().split('.').last == discountTypeStr,
            orElse: () => DiscountType.PERCENTAGE
          );
        } catch (e) {
          print('Error parsing discount type: $e');
          discountType = DiscountType.PERCENTAGE;
        }
      }
      
      // Parse source with default value
      CampaignSource source = CampaignSource.MANUAL;  // Default value
      if (json['source'] != null) {
        try {
          String sourceStr = (json['source'] as String? ?? '')
            .replaceFirst('CAMPAIGNSOURCE.', '') // Remove prefix if exists
            .replaceFirst('CampaignSource.', ''); // Remove another possible prefix
          source = CampaignSource.values.firstWhere(
            (e) => e.toString().split('.').last == sourceStr,
            orElse: () => CampaignSource.MANUAL
          );
        } catch (e) {
          print('Error parsing source: $e');
          source = CampaignSource.MANUAL;
        }
      }
      
      // Handle dates directly as DateTime objects
      final startDate = DateTime.parse(json['start_date'] ?? json['startDate']);
      final endDate = DateTime.parse(json['end_date'] ?? json['endDate']);
      final createdAt = DateTime.parse(json['created_at'] ?? json['createdAt']);

      return Campaign(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        category: (json['category'] as String?) ?? 'Genel',
        categoryName: json['campaign_category_name'] as String?,
        categoryId: json['category_id'] as int?,
        discountType: discountType,
        discountValue: (json['discount_value'] as num?)?.toDouble(),
        minAmount: (json['min_amount'] as num?)?.toDouble() ?? 0.0,
        maxDiscount: (json['max_discount'] as num?)?.toDouble(),
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
        priority: json['priority'] as int? ?? 0,
        merchantId: json['merchant_id'] as int?,
        isActive: json['is_active'] as bool? ?? true,
        bank: bank,
        creditCard: creditCard,
        requiresEnrollment: json['requires_enrollment'] as bool? ?? false,
        enrollmentUrl: json['enrollment_url'] as String?,
        merchant: merchant,
        source: source,
      );
    } catch (e, stackTrace) {
      print('Error parsing campaign JSON: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': _description,
      'category': category,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'discountType': discountType?.toString().split('.').last, // Remove enum prefix
      'discountValue': discountValue,
      'minAmount': minAmount,
      'maxDiscount': maxDiscount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'merchantId': merchantId,
      'isActive': isActive,
      'bank': bank?.toJson(),
      'creditCard': creditCard?.toJson(),
      'requiresEnrollment': requiresEnrollment,
      'enrollmentUrl': enrollmentUrl,
      'merchant': merchant?.toJson(),
      'source': source.toString().split('.').last, // Remove enum prefix
    };
  }

  // UI helper properties
  String get formattedDiscount {
    if (discountType == DiscountType.PERCENTAGE) {
      return '%${discountValue?.toStringAsFixed(0) ?? '0'}';
    } else if (discountType == DiscountType.CASHBACK) {
      return '${discountValue?.toStringAsFixed(0) ?? '0'} TL';
    } else if (discountType == DiscountType.POINTS) {
      return '${discountValue?.toStringAsFixed(0) ?? '0'} Puan';
    } else {
      return '${discountValue?.toStringAsFixed(0) ?? '0'} TL İndirim';
    }
  }

  String get timeRemaining {
    final difference = endDate.difference(DateTime.now());
    if (difference.inDays > 0) {
      return '${difference.inDays} gün kaldı';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat kaldı';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika kaldı';
    } else {
      return 'Süresi doldu';
    }
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  String get trimmedDescription {
    if (_description.length <= 100) return _description;
    return '${_description.substring(0, 100)}...';
  }
}

class Bank {
  final int id;
  final String name;
  final String? logoUrl;
  
  Bank({
    required this.id,
    required this.name,
    this.logoUrl,
  });
  
  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Bank',
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
    };
  }
}

class CreditCard {
  final int id;
  final String name;
  final int bankId;
  final String cardType;
  final String cardTier;
  final double? annualFee;
  final double? rewardsRate;
  final String? applicationUrl;
  final String? affiliateCode;
  final String? logoUrl;
  final bool isActive;
  
  CreditCard({
    required this.id,
    required this.name,
    required this.bankId,
    required this.cardType,
    required this.cardTier,
    this.annualFee,
    this.rewardsRate,
    this.applicationUrl,
    this.affiliateCode,
    this.logoUrl,
    required this.isActive,
  });
  
  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Card',
      bankId: json['bank_id'] ?? 0,
      cardType: json['card_type'] ?? 'unknown',
      cardTier: json['card_tier'] ?? 'standard',
      annualFee: json['annual_fee'] != null ? (json['annual_fee']).toDouble() : null,
      rewardsRate: json['rewards_rate'] != null ? (json['rewards_rate']).toDouble() : null,
      applicationUrl: json['application_url'],
      affiliateCode: json['affiliate_code'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bank_id': bankId,
      'card_type': cardType,
      'card_tier': cardTier,
      'annual_fee': annualFee,
      'rewards_rate': rewardsRate,
      'application_url': applicationUrl,
      'affiliate_code': affiliateCode,
      'logo_url': logoUrl,
      'is_active': isActive,
    };
  }
}

class Merchant {
  final int id;
  final String name;
  final String categories;
  final String? logoUrl;
  
  Merchant({
    required this.id,
    required this.name,
    required this.categories,
    this.logoUrl,
  });
  
  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Merchant',
      categories: json['categories'] ?? '',
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categories': categories,
      'logo_url': logoUrl,
    };
  }
} 