class UserCreditCard {
  final int id;
  final String bankName;
  final String cardName;
  final bool isActive;
  final DateTime createdAt;

  UserCreditCard({
    required this.id,
    required this.bankName,
    required this.cardName,
    required this.isActive,
    required this.createdAt,
  });

  factory UserCreditCard.fromJson(Map<String, dynamic> json) {
    return UserCreditCard(
      id: json['id'],
      bankName: json['bank_name'],
      cardName: json['card_name'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_name': bankName,
      'card_name': cardName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 