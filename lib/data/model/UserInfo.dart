class UserInfo {  
  int? userId; // Foreign key  
  String? address;  
  String? contact;  
  DateTime? birthday;  
  String? avatarUrl;  

  UserInfo({  
    required this.userId,  
    required this.address,  
    required this.contact,  
    required this.birthday,  
    required this.avatarUrl,  
  });  

  Map<String, dynamic> toMap() {  
    return {  
      'user_id': userId,  
      'address': address,  
      'contact': contact,  
      'birthday': birthday?.toIso8601String(), // Convert to string for storage  
      'avatar_url': avatarUrl,  
    };  
  }  

  factory UserInfo.fromMap(Map<String, dynamic> map) {  
    return UserInfo(  
      userId: map['user_id'],  
      address: map['address'],  
      contact: map['contact'],  
      birthday: DateTime.parse(map['birthday']),  
      avatarUrl: map['avatar_url'],  
    );  
  }  
}