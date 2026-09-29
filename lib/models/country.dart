class Country {
  final String name;
  final String flagUrl;
  final String iso2;
  final String iso3;

  Country({
    required this.name,
    required this.flagUrl,
    required this.iso2,
    required this.iso3,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    final iso2 = json['iso2'] as String? ?? '';
    final flagUrl = json['flag'] as String? ??
        'https://flagcdn.com/w320/${iso2.toLowerCase()}.png';

    return Country(
      name: json['name'] as String? ?? 'Unknown',
      flagUrl: flagUrl,
      iso2: iso2,
      iso3: json['iso3'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          iso2 == other.iso2;

  @override
  int get hashCode => iso2.hashCode;
}
