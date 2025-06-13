class Offer {
  final int id;
  final String title;
  final String description;
  final String companyName;
  final String companyLogoUrl;
  final int? categoryId;
  final int cityId;
  final String backgroundImageUrl;

  String? categoryName;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.companyName,
    required this.companyLogoUrl,
    this.categoryId,
    required this.cityId,
    required this.backgroundImageUrl,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    companyName: json['companyName'],
    companyLogoUrl: json['companyLogoUrl'],
    categoryId: json['category_id'],
    cityId: json['city_id'],
    backgroundImageUrl: json['backgroundImageUrl'],
  );
}
