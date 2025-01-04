class Doctor {
  final String name;
  final String updatedHistory;
  final String avatar;

  Doctor({
    required this.name,
    required this.updatedHistory,
    required this.avatar,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      name: map['name'] as String,
      updatedHistory: map['updated_history'] as String,
      avatar: map['avatar'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'updated_history': updatedHistory,
      'avatar': avatar,
    };
  }
}
