import 'dart:convert';

class Data {
  String salt;
  String iv;
  String note;

  Data({required this.salt, required this.iv, required this.note});

  factory Data.fromJson(Map<String, dynamic> jsonData) {
    return Data(salt: jsonData['salt'], iv: jsonData['iv'], note: jsonData['note']);
  }

  static Map<String, dynamic> toMap(Data model) => {
        'salt': model.salt,
        'iv': model.iv,
        'note': model.note,
      };

  static String serialize(Data model) => jsonEncode(Data.toMap(model));

  static Data deserialize(String json) => Data.fromJson(jsonDecode(json));
}
