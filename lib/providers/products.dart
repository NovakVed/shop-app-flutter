import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];
  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final param = filterByUser
        ? {
            'auth': authToken,
            'orderBy': jsonEncode("creatorId"),
            'equalTo': jsonEncode(userId)
          }
        : {'auth': authToken};

    var url = Uri.https(
        'flutter-update-9aafe-default-rtdb.europe-west1.firebasedatabase.app',
        '/products.json',
        param);
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final loadedProducts = <Product>[];
      if (extractedData == null) {
        return;
      }
      url = Uri.https(
          'flutter-update-9aafe-default-rtdb.europe-west1.firebasedatabase.app',
          '/userFavorites/$userId.json',
          {'auth': '$authToken'});
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);

      extractedData.forEach(
        (prodId, prodData) {
          loadedProducts.add(
            Product(
              id: prodId,
              title: prodData['title'],
              description: prodData['description'],
              price: prodData['price'],
              imageUrl: prodData['imageUrl'],
              isFavorite:
                  favoriteData == null ? false : favoriteData[prodId] ?? false,
            ),
          );
        },
      );
      _items = loadedProducts;
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.https(
        'flutter-update-9aafe-default-rtdb.europe-west1.firebasedatabase.app',
        '/products.json',
        {'auth': '$authToken'});
    try {
      final response = await http.post(
        url,
        body: json.encode({
          // 'id': product.id,
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'creatorId': userId,
        }),
      );
      final newProduct = Product(
          id: json.decode(response.body)['name'],
          title: product.title,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl);
      _items.add(newProduct);
      // _items.insert(0, newProduct); // at the start of the list
      notifyListeners();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final url = Uri.https(
        'flutter-update-9aafe-default-rtdb.europe-west1.firebasedatabase.app',
        '/products/$id.json',
        {'auth': '$authToken'});
    try {
      await http.patch(
        url,
        body: json.encode(
          {
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          },
        ),
      );
    } catch (e) {
      print(e);
    }
    final prodIndex = _items.indexWhere((product) => product.id == id);
    if (prodIndex >= 0) {
      _items[prodIndex] = newProduct;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.https(
        'flutter-update-9aafe-default-rtdb.europe-west1.firebasedatabase.app',
        '/products/$id.json',
        {'auth': '$authToken'});
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];

    _items.removeWhere((product) => product.id == id);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      HttpException('Could not delete product!');
    }
    existingProduct = null;
  }
}
