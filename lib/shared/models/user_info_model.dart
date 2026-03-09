class UserInfoModel {
  final String name;
  final String houseNumber;
  final String? email;
  final String? phone;

  UserInfoModel({
    required this.name,
    required this.houseNumber,
    this.email,
    this.phone,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      name: json['name'] as String? ?? 'Unknown',
      houseNumber: json['house_number'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'house_number': houseNumber,
      'email': email,
      'phone': phone,
    };
  }
}
