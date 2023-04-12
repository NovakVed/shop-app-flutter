import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.price,
    @required this.imageUrl,
    this.isFavorite = false,
  });

  void _setFavValue(bool value) {
    isFavorite = value;
    notifyListeners();
  }

  Future<void> toggleFavoriteStatus(
      String id, String authToken, String userId) async {
    var oldStatus = isFavorite;
    final url = Uri.https(
        'flutter-update-9aafe-default-rtdb.europe-west1.firebasedatabase.app',
        '/userFavorites/$userId/$id.json',
        {'auth': '$authToken'});
    try {
      final response = await http.put(url, body: json.encode(!isFavorite));
      _setFavValue(!isFavorite);

      if (response.statusCode >= 400) {
        _setFavValue(oldStatus);
        HttpException('Could not change status of favorite product!');
      }
    } catch (e) {
      _setFavValue(oldStatus);
      HttpException('Could not change status of favorite product!');
    }
    oldStatus = null;
  }
}
