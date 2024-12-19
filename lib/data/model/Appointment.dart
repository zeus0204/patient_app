class Appointment {
  int? id;
  int userId;
  int? doctor_id;
  int? hospital_id;
  DateTime? day;
  String? time;

  Appointment({
    this.id,
    required this.userId,
    required this.doctor_id,
    required this.hospital_id,
    required this.day,
    required this.time,
  });

  // Convert a Appointment object into a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'doctor_id': doctor_id,
      'hospital_id': hospital_id,
      'day': day,
      'time': time
    };
  }

  // Create a Appointment object from a database Map
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      userId: map['user_id'],
      doctor_id: map['doctor_id'],
      hospital_id: map['hospital_id'],
      day: map['day'] != null ? DateTime.parse(map['day']) : null,
      time: map['time']
    );
  }
}
