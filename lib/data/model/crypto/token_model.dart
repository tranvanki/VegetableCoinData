class TokenModel {
  final String id;
  final String symbol;
  final String name;
  final Map<String, String> platforms;

  TokenModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.platforms,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      platforms: Map<String, String>.from(json['platforms'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'platforms': platforms,
    };
  }

  static List<TokenModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((e) => TokenModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
