import 'dart:convert';

class Data {
  String salt;
  String ivKey;
  String keyEncrypted;
  String ivNote;
  String noteEncrypted;

  Data({
    required this.salt,
    required this.ivKey,
    required this.keyEncrypted,
    required this.ivNote,
    required this.noteEncrypted,
  });

  factory Data.fromJson(Map<String, dynamic> jsonData) {
    return Data(
        salt: jsonData['salt'],
        ivKey: jsonData['ivKey'],
        keyEncrypted: jsonData['keyEncrypted'],
        ivNote: jsonData['ivNote'],
        noteEncrypted: jsonData['noteEncrypted']);
  }

  static Map<String, dynamic> toMap(Data model) => {
        'salt': model.salt,
        'ivKey': model.ivKey,
        'keyEncrypted': model.keyEncrypted,
        'ivNote': model.ivNote,
        'noteEncrypted': model.noteEncrypted,
      };

  static String serialize(Data model) => jsonEncode(Data.toMap(model));

  static Data deserialize(String json) => Data.fromJson(jsonDecode(json));
}
