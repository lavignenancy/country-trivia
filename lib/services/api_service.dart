import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class ApiService {
  static const String _baseUrl =
      'https://countriesnow.space/api/v0.1/countries/flag/images';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Country>> fetchCountries() async {
    final response = await _client.get(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> countriesJson = data['data'];
      return countriesJson.map((json) => Country.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load countries: ${response.statusCode}');
    }
  }
}
