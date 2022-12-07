import 'dart:convert';

class Data {
  String saltKey;
  String saltDeviceID;
  String iv;

  Data({required this.saltKey, required this.saltDeviceID, required this.iv});

  factory Data.fromJson(Map<String, dynamic> jsonData) {
    return Data(saltKey: jsonData['saltKey'], saltDeviceID: jsonData['saltDeviceID'], iv: jsonData['iv']);
  }

  static Map<String, dynamic> toMap(Data model) => {
        'saltKey': model.saltKey,
        'saltDeviceID': model.saltDeviceID,
        'iv': model.iv,
      };

  static String serialize(Data model) => jsonEncode(Data.toMap(model));

  static Data deserialize(String json) => Data.fromJson(jsonDecode(json));
}
