import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/offer.dart';

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
  static const String _baseUrl = 'https://laboba.com/api/offers';

  Future<List<String>> fetchCities() async {
    final uri = Uri.parse('$_baseUrl/cities');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load cities: ${response.statusCode}');
    }
    final data = json.decode(response.body) as List<dynamic>;
    return data.map((e) => e as String).toList();
  }

  Future<Map<String, dynamic>> fetchOffers({
    required int offset,
    required String city,
    int? categoryId,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'offset': offset.toString(),
      'city': city,
      if (categoryId != null) 'categoryId': categoryId.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    // В data должны быть «categories» и «offers»
    final catsJson = data['categories'] as List<dynamic>;
    final offersJson = data['offers'] as List<dynamic>;

    final categories =
    catsJson.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    final offers =
    offersJson.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();

    return {
      'categories': categories,
      'offers': offers,
    };
  }
}
