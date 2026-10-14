class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? city;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.city,
    this.photoUrl,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      city: data['city'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
