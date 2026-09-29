import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/country.dart';

void main() {
  group('Country', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'name': 'Germany',
        'flag': 'https://flagcdn.com/w320/de.png',
        'iso2': 'DE',
        'iso3': 'DEU',
      };

      final country = Country.fromJson(json);

      expect(country.name, 'Germany');
      expect(country.flagUrl, 'https://flagcdn.com/w320/de.png');
      expect(country.iso2, 'DE');
      expect(country.iso3, 'DEU');
    });

    test('fromJson constructs flag URL from iso2 when flag is missing', () {
      final json = {
        'name': 'France',
        'iso2': 'FR',
        'iso3': 'FRA',
      };

      final country = Country.fromJson(json);

      expect(country.flagUrl, 'https://flagcdn.com/w320/fr.png');
    });

    test('fromJson handles null name gracefully', () {
      final json = {
        'iso2': 'US',
        'iso3': 'USA',
      };

      final country = Country.fromJson(json);

      expect(country.name, 'Unknown');
    });

    test('equality is based on iso2', () {
      final a = Country(
        name: 'Germany',
        flagUrl: 'https://flagcdn.com/w320/de.png',
        iso2: 'DE',
        iso3: 'DEU',
      );
      final b = Country(
        name: 'Deutschland',
        flagUrl: 'https://flagcdn.com/w320/de.png',
        iso2: 'DE',
        iso3: 'DEU',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality for different iso2', () {
      final a = Country(
        name: 'Germany',
        flagUrl: 'https://flagcdn.com/w320/de.png',
        iso2: 'DE',
        iso3: 'DEU',
      );
      final b = Country(
        name: 'France',
        flagUrl: 'https://flagcdn.com/w320/fr.png',
        iso2: 'FR',
        iso3: 'FRA',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
