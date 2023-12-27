class Data {
  final String salt;
  final String ivKey;
  final String keyEncrypted;
  final String ivNote;
  final String noteEncrypted;

  Data(
    this.salt,
    this.ivKey,
    this.keyEncrypted,
    this.ivNote,
    this.noteEncrypted,
  );

  Data.fromJson(Map<String, dynamic> json)
      : salt = json['salt'] as String,
        ivKey = json['ivKey'] as String,
        keyEncrypted = json['keyEncrypted'] as String,
        ivNote = json['ivNote'] as String,
        noteEncrypted = json['noteEncrypted'] as String;

  Map<String, dynamic> toJson() => {
        'salt': salt,
        'ivKey': ivKey,
        'keyEncrypted': keyEncrypted,
        'ivNote': ivNote,
        'noteEncrypted': noteEncrypted,
      };
}
