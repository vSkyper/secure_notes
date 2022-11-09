import 'dart:convert';

class Encrypted {
  String salt;
  String iv;
  String note;

  Encrypted({required this.salt, required this.iv, required this.note});

  factory Encrypted.fromJson(Map<String, dynamic> jsonData) {
    return Encrypted(salt: jsonData['salt'], iv: jsonData['iv'], note: jsonData['note']);
  }

  static Map<String, dynamic> toMap(Encrypted model) => {
        'salt': model.salt,
        'iv': model.iv,
        'note': model.note,
      };

  static String serialize(Encrypted model) => jsonEncode(Encrypted.toMap(model));

  static Encrypted deserialize(String json) => Encrypted.fromJson(jsonDecode(json));
}
