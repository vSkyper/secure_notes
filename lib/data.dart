class Data {
  final String salt;
  final String ivKey;
  final String key;
  final String ivNote;
  final String note;

  Data(
    this.salt,
    this.ivKey,
    this.key,
    this.ivNote,
    this.note,
  );

  Data.fromJson(Map<String, dynamic> json)
      : salt = json['salt'] as String,
        ivKey = json['ivKey'] as String,
        key = json['key'] as String,
        ivNote = json['ivNote'] as String,
        note = json['note'] as String;

  Map<String, dynamic> toJson() => {
        'salt': salt,
        'ivKey': ivKey,
        'key': key,
        'ivNote': ivNote,
        'note': note,
      };
}
