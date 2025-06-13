import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/offer.dart';
import '../models/city.dart';
import 'api_client.dart';

import 'auth_storage.dart';

class Repository {
  Future<Map<String, dynamic>> loadData() async {
    final jsonString = await rootBundle.loadString('assets/data/offers.json');
    final data = json.decode(jsonString);
    final cats = (data['categories'] as List)
        .map((e) => Category.fromJson(e))
        .toList();
    final offers = (data['offers'] as List)
        .map((e) => Offer.fromJson(e))
        .toList();
    return {
      'categories': cats,
      'offers': offers,
    };
  }
}

/// /api/offers?offset=<offset>&city=<city>&categoryId=<categoryId>
/// /api/cities
///
/// server return <= 5 offers и категории связанные с ними
///
class Repository2 {

  Future<List<City>> fetchCities() async {
    final uri = Uri.parse('/cities');

    final response = await ApiClient.instance.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load cities: ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as List<dynamic>;
    final data = decoded
        .map((e) => City.fromJson(e))
        .toList();
    return data;
  }

  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse("/categories");

    final response = await ApiClient.instance.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    final catsJson = json.decode(response.body) as List<dynamic>;
    final data = catsJson
        .map((e) => e as Map<String, dynamic>)
        .toList();
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Offer>> fetchOffers({
    required int offset,
    required int city,
    required int categoryId,
  }) async {
    final uri = Uri.parse("/offers").replace(queryParameters: {
      'offset': offset.toString(),
      'city_id': city.toString(),
      'category_id': categoryId.toString(),
    });

    final response = await ApiClient.instance.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    final accessToken = response.headers["x-access-token"];
    if (accessToken != null){
      await AuthStorage().saveToken(accessToken);
    }

    final offersJson = json.decode(response.body) as List<dynamic>;
    final data = offersJson
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final offers = data.map((e) => Offer.fromJson(e)).toList();

    return offers;
  }
}
