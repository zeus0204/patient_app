class MedicalHistory {
  int? id;
  int userId;
  String title;
  String subtitle;
  String description;

  MedicalHistory({
    this.id,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  // Convert a MedicalHistory object into a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
    };
  }

  // Create a MedicalHistory object from a database Map
  factory MedicalHistory.fromMap(Map<String, dynamic> map) {
    return MedicalHistory(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      subtitle: map['subtitle'],
      description: map['description'],
    );
  }
}
