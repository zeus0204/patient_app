class User {
  int? id;
  String? fullName;
  String? email;
  String? phoneNumber;
  String? password;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      password: map['password'],
    );
  }
}