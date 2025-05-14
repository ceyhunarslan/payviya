class CreditCardListItem {
  final int? id;
  final int creditCardId;
  final String? creditCardName;
  final String? creditCardLogoUrl;
  final String? bankName;
  final String? bankLogoUrl;

  CreditCardListItem({
    this.id,
    required this.creditCardId,
    this.creditCardName,
    this.creditCardLogoUrl,
    this.bankName,
    this.bankLogoUrl,
  });

  factory CreditCardListItem.fromJson(Map<String, dynamic> json) {
    return CreditCardListItem(
      id: json['id'],
      creditCardId: json['credit_card_id'],
      creditCardName: json['credit_card_name'],
      creditCardLogoUrl: json['credit_card_logo_url'],
      bankName: json['bank_name'],
      bankLogoUrl: json['bank_logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credit_card_id': creditCardId,
      'credit_card_name': creditCardName,
      'credit_card_logo_url': creditCardLogoUrl,
      'bank_name': bankName,
      'bank_logo_url': bankLogoUrl,
    };
  }
} 