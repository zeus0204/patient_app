class Schedule {
  final String doctor;
  final String address;
  final String dayTime;
  final String startTime;
  final String endTime;
  final String avatar;

  Schedule({
    required this.doctor,
    required this.address,
    required this.dayTime,
    required this.startTime,
    required this.endTime,
    required this.avatar,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      doctor: map['doctor'] as String,
      address: map['address'] as String,
      dayTime: map['day_time'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      avatar: map['avatar'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctor': doctor,
      'address': address,
      'day_time': dayTime,
      'start_time': startTime,
      'end_time': endTime,
      'avatar': avatar,
    };
  }
}
