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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Merchant',
      categories: json['categories'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
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

  // Helper method to get categories as a list
  List<String> get categoriesList => categories.split(',').where((c) => c.isNotEmpty).toList();
} 