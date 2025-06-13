import '../models/category.dart';
import '../models/offer.dart';

class OffersCategoriesResponse {
  final List<Offer> offers;
  final List<Category> categories;

  OffersCategoriesResponse({
    required this.offers,
    required this.categories,
  });
}