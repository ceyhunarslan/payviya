class Campaign {
  final int id;
  final String name;
  final String description;
  final int bankId;
  final int cardId;
  final String category;
  final String discountType;
  final double discountValue;
  final double minAmount;
  final double? maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final int? merchantId;
  final bool isActive;
  final bool requiresEnrollment;
  final String? enrollmentUrl;
  final String source;
  final String status;
  final String? externalId;
  final int priority;
  final DateTime? lastSyncAt;
  final String? reviewNotes;
  final int? reviewedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Related entity data
  final Bank? bank;
  final CreditCard? creditCard;
  final Merchant? merchant;
  
  // UI helper properties
  String get formattedDiscount {
    if (discountType == 'percentage') {
      return '%${discountValue.toStringAsFixed(0)}';
    } else if (discountType == 'cashback') {
      return '${discountValue.toStringAsFixed(0)} TL Geri Ödeme';
    } else if (discountType == 'points') {
      return '${discountValue.toStringAsFixed(0)} Puan';
    } else {
      return '${discountValue.toStringAsFixed(0)} TL İndirim';
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
  
  Campaign({
    required this.id,
    required this.name,
    required this.description,
    required this.bankId,
    required this.cardId,
    required this.category,
    required this.discountType,
    required this.discountValue,
    required this.minAmount,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    this.merchantId,
    required this.isActive,
    required this.requiresEnrollment,
    this.enrollmentUrl,
    required this.source,
    required this.status,
    this.externalId,
    required this.priority,
    this.lastSyncAt,
    this.reviewNotes,
    this.reviewedBy,
    required this.createdAt,
    this.updatedAt,
    this.bank,
    this.creditCard,
    this.merchant,
  });
  
  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      bankId: json['bank_id'],
      cardId: json['card_id'],
      category: json['category'],
      discountType: json['discount_type'],
      discountValue: json['discount_value'].toDouble(),
      minAmount: json['min_amount']?.toDouble() ?? 0,
      maxDiscount: json['max_discount']?.toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      merchantId: json['merchant_id'],
      isActive: json['is_active'] ?? true,
      requiresEnrollment: json['requires_enrollment'] ?? false,
      enrollmentUrl: json['enrollment_url'],
      source: json['source'] ?? 'manual',
      status: json['status'] ?? 'approved',
      externalId: json['external_id'],
      priority: json['priority'] ?? 0,
      lastSyncAt: json['last_sync_at'] != null 
          ? DateTime.parse(json['last_sync_at'])
          : null,
      reviewNotes: json['review_notes'],
      reviewedBy: json['reviewed_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
      creditCard: json['credit_card'] != null 
          ? CreditCard.fromJson(json['credit_card'])
          : null,
      merchant: json['merchant'] != null 
          ? Merchant.fromJson(json['merchant'])
          : null,
    );
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
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
    );
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
      id: json['id'],
      name: json['name'],
      bankId: json['bank_id'],
      cardType: json['card_type'],
      cardTier: json['card_tier'],
      annualFee: json['annual_fee']?.toDouble(),
      rewardsRate: json['rewards_rate']?.toDouble(),
      applicationUrl: json['application_url'],
      affiliateCode: json['affiliate_code'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
    );
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
      id: json['id'],
      name: json['name'],
      categories: json['categories'],
      logoUrl: json['logo_url'],
    );
  }
} 