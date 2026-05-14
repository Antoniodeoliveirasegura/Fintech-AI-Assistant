class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String memberSince;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        memberSince: json['member_since'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'member_since': memberSince,
      };

  String get firstName => name.split(' ').first;
}
