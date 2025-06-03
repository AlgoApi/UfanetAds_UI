class Offer {
  final int id;
  final String title;
  final String description;
  final String companyName;
  final String companyLogoUrl;
  final int categoryId;
  final String city;
  final String backgroundImageUrl;

  String? categoryName;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.companyName,
    required this.companyLogoUrl,
    required this.categoryId,
    required this.city,
    required this.backgroundImageUrl,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    companyName: json['companyName'],
    companyLogoUrl: json['companyLogoUrl'],
    categoryId: json['categoryId'],
    city: json['city'],
    backgroundImageUrl: json['backgroundImageUrl'],
  );
}
