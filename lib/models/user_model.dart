class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String accountType;
  
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accountType,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      accountType: json['user_type'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'user_type': accountType,
    };
  }
  
  String get fullName => '$firstName $lastName';
  
  bool get isStudent => accountType.toLowerCase() == 'student';
  bool get isTutor => accountType.toLowerCase() == 'tutor';
}