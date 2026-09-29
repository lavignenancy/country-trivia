import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:country_trivia/services/api_service.dart';

void main() {
  group('ApiService', () {
    final sampleResponse = jsonEncode({
      'error': false,
      'msg': 'countries and flags retrieved',
      'data': [
        {
          'name': 'Germany',
          'flag': 'https://flagcdn.com/w320/de.png',
          'iso2': 'DE',
          'iso3': 'DEU',
        },
        {
          'name': 'France',
          'flag': 'https://flagcdn.com/w320/fr.png',
          'iso2': 'FR',
          'iso3': 'FRA',
        },
      ],
    });

    test('fetchCountries returns list of Country on 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(sampleResponse, 200);
      });

      final service = ApiService(client: mockClient);
      final countries = await service.fetchCountries();

      expect(countries.length, 2);
      expect(countries[0].name, 'Germany');
      expect(countries[0].iso2, 'DE');
      expect(countries[1].name, 'France');
      expect(countries[1].iso2, 'FR');
    });

    test('fetchCountries throws on non-200 status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = ApiService(client: mockClient);

      expect(
        () => service.fetchCountries(),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchCountries throws on 500 status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = ApiService(client: mockClient);

      expect(
        () => service.fetchCountries(),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchCountries sends correct headers', () async {
      Map<String, String>? capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(sampleResponse, 200);
      });

      final service = ApiService(client: mockClient);
      await service.fetchCountries();

      expect(capturedHeaders?['Content-Type'], 'application/json');
    });
  });
}
